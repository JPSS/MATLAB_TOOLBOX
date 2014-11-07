function y = gauss_convolve_step(x,sigma,stepEnd,stepHeight,stepStart)
%% fit of gaussian with width sigma convolved with step function starting from x=stepStart to x=stepEnd with y=stepHeight
%   x
%   sigma width of gaussian
%   stepEnd end of step function
%   stepHeight height of step function
%   stepStart start of step function

y=(1/2)*stepHeight*(-erf((stepStart-x)/(sqrt(2)*sigma))+erf((stepEnd-x)/(sqrt(2)*sigma)));