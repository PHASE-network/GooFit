#include "goofit/PDFs/EventWeightedAddPdf.h"

EXEC_TARGET fptype device_EventWeightedAddPdfs(fptype* evt, fptype* p, unsigned int* indices) {
    int numParameters = RO_CACHE(indices[0]);
    fptype ret = 0;
    fptype totalWeight = 0;

    for(int i = 0; i < numParameters/2 - 1; ++i) {
        fptype weight = RO_CACHE(evt[RO_CACHE(indices[2 + numParameters + i])]);
        totalWeight += weight;
        fptype curr = callFunction(evt, RO_CACHE(indices[2*i + 1]), RO_CACHE(indices[2*(i+1)]));
        ret += weight * curr * normalisationFactors[RO_CACHE(indices[2*(i+1)])];
    }

    // numParameters does not count itself. So the array structure for two functions is
    // nP | F P | F P | nO | o1
    // in which nP = 4. and nO = 1. Therefore the parameter index for the last function pointer is nP, and the function index is nP-1.
    //fptype last = (*(reinterpret_cast<device_function_ptr>(device_function_table[indices[numParameters-1]])))(evt, p, paramIndices + indices[numParameters]);
    fptype last = callFunction(evt, RO_CACHE(indices[numParameters-1]), RO_CACHE(indices[numParameters]));
    ret += (1 - totalWeight) * last * normalisationFactors[RO_CACHE(indices[numParameters])];

    return ret;
}

EXEC_TARGET fptype device_EventWeightedAddPdfsExt(fptype* evt, fptype* p, unsigned int* indices) {
    // numParameters does not count itself. So the array structure for two functions is
    // nP | F P | F P | nO | o1 o2
    // in which nP = 4, nO = 2.

    int numParameters = RO_CACHE(indices[0]);
    fptype ret = 0;
    fptype totalWeight = 0;

    for(int i = 0; i < numParameters/2; ++i) {
        fptype curr = callFunction(evt, RO_CACHE(indices[2*i + 1]), RO_CACHE(indices[2*(i+1)]));
        //if ((0 == BLOCKIDX) && (THREADIDX < 5) && (isnan(curr))) printf("NaN component %i %i\n", i, THREADIDX);
        fptype weight = RO_CACHE(evt[RO_CACHE(indices[2 + numParameters + i])]);
        ret += weight * curr * normalisationFactors[RO_CACHE(indices[2*(i+1)])];
        totalWeight += weight;

        //if ((gpuDebug & 1) && (0 == THREADIDX))
        //if ((gpuDebug & 1) && (1 > evt[8]))
        //if ((gpuDebug & 1) && (0 == THREADIDX) && (0 == BLOCKIDX))
        //printf("EventWeightedExt: %i %f %f | %f %f %f %f %f %f %f\n", i, curr, weight, evt[0], evt[1], evt[2], evt[3], evt[4], evt[5], evt[6]);
        //printf("EventWeightedExt: %i %f %f | %f %f \n", i, curr, weight, normalisationFactors[indices[2*(i+1)]], curr * normalisationFactors[indices[2*(i+1)]]);
        //printf("EventWeightedExt: %i : %i %.10f %.10f %.10f %f %f %f\n", (int) floor(0.5 + evt[8]), i, curr, weight, ret, normalisationFactors[indices[2*(i+1)]], evt[6], evt[7]);
    }

    ret /= totalWeight;

    //if (0 >= ret) printf("Zero sum %f %f %f %f %f %f %f %f %f %f\n", evt[0], evt[1], evt[2], evt[3], evt[4], evt[5], evt[6], evt[7], evt[8], evt[9]);

    return ret;
}

MEM_DEVICE device_function_ptr ptr_to_EventWeightedAddPdfs = device_EventWeightedAddPdfs;
MEM_DEVICE device_function_ptr ptr_to_EventWeightedAddPdfsExt = device_EventWeightedAddPdfsExt;

EventWeightedAddPdf::EventWeightedAddPdf(std::string n, std::vector<Variable*> weights, std::vector<PdfBase*> comps)
    : GooPdf(0, n) {
    assert((weights.size() == comps.size()) || (weights.size() + 1 == comps.size()));

    // Indices stores (function index)(function parameter index) doublet for each component.
    // Last component has no weight index unless function is extended. Notice that in this case, unlike
    // AddPdf, weight indices are into the event, not the parameter vector, hence they
    // are not added to the pindices array at this stage, although 'initialise' will reserve space
    // for them.
    for(std::vector<PdfBase*>::iterator p = comps.begin(); p != comps.end(); ++p) {
        //std::cout << "EventWeighted component: " << (*p)->getName() << std::endl;
        components.push_back(*p);
        assert(components.back());
    }

    bool extended = true;
    std::vector<unsigned int> pindices;

    for(unsigned int w = 0; w < weights.size(); ++w) {
        assert(components[w]);
        pindices.push_back(components[w]->getFunctionIndex());
        pindices.push_back(components[w]->getParameterIndex());
        registerObservable(weights[w]);
    }

    assert(components.back());

    if(weights.size() < components.size()) {
        pindices.push_back(components.back()->getFunctionIndex());
        pindices.push_back(components.back()->getParameterIndex());
        extended = false;
    }

    // This must occur after registering weights, or the indices will be off - the device functions assume that the weights are first.
    getObservables(observables);

    if(extended)
        GET_FUNCTION_ADDR(ptr_to_EventWeightedAddPdfsExt);
    else
        GET_FUNCTION_ADDR(ptr_to_EventWeightedAddPdfs);

    initialise(pindices);
}

__host__ fptype EventWeightedAddPdf::normalise() const {
    //if (cpuDebug & 1) std::cout << "Normalising EventWeightedAddPdf " << getName() << " " << components.size() << std::endl;

    // Here the PDFs have per-event weights, so there is no per-PDF weight
    // to keep track of. All we can do is normalise the components.
    for(unsigned int i = 0; i < components.size(); ++i) {
        components[i]->normalise();
    }

    host_normalisation[parameters] = 1.0;

    return 1.0;
}

