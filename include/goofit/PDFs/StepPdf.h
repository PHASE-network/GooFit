#ifndef STEP_PDF_HH
#define STEP_PDF_HH

#include "goofit/PDFs/GooPdf.h"

class StepPdf : public GooPdf {
public:
    StepPdf(std::string n, Variable* _x, Variable* x0);
    __host__ fptype integrate(fptype lo, fptype hi) const;
    __host__ virtual bool hasAnalyticIntegral() const {
        return true;
    }



private:

};

#endif
