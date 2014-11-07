function y = gaussConvolveStep(sigma,stepStart,stepEnd,stepHeight)
%% fit of gaussian with width sigma convolved with step function starting from x=stepStart to x=stepEnd with y=stepHeight
%   sigma width of gaussian
%   stepStart start of step function
%   stepEnd end of step function
%   stepHeight height of step function

y=(1/2)*stepHeight*(-erf((stepStart-x)/(sqrt(2)*sigma))+erf((stepEnd-x)/(sqrt(2)*sigma)));