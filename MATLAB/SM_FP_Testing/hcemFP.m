%used for fixed point designer

function [result1,result2,result3,result4] = hcemFP(x,An,target)

    TRs = An*target;
    SRs = target'*TRs;
    TRx = An*x;
    SRx = target'*TRx;
    XRx = x'*TRx;
    SRx2 = SRx*SRx;
    XRx2 = XRx*XRx;
    SRxAb = abs(SRx);
    XRxAb = abs(XRx);
    tmp2 = SRs*XRx;
    tmp3 = SRx*SRxAb;
    tmp4 = SRs*XRxAb;
    tmp5 = SRx*SRx2;
    tmp6 = SRs*XRx2;
    
    
    result1 = SRx/SRs;
    result2 = SRx2/tmp2;
    result3 = tmp3/tmp4;
    result4 = tmp5/tmp6;
    
end