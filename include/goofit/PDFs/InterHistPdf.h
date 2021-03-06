#ifndef INTERHIST_PDF_HH
#define INTERHIST_PDF_HH

#include "goofit/PDFs/GooPdf.h"
#include "goofit/BinnedDataSet.h"

class InterHistPdf : public GooPdf {
public:
    InterHistPdf(std::string n,
                 BinnedDataSet* x,
                 std::vector<Variable*> params,
                 std::vector<Variable*> obses);
    //__host__ virtual fptype normalise () const;

private:
    thrust::device_vector<fptype>* dev_base_histogram;
    fptype totalEvents;
    fptype* host_constants;
    int numVars;
};

#endif
