function [ integral ] = gauss_convolve_step_integral( parameters, xStart, xEnd )
%   Integral over Convolution of a normalized gaussian function with
%   a stepfunction, from xStart to xEnd
%   stepHeight is height of the stepfunction, stepStart is the beginning of
%   the stepfunction, stepEnd is the end of the stepfunction, sigma is the
%   standard deviation of the gaussian, x is the x value to be evaluated

sigma=parameters(1);
stepEnd=parameters(2);
stepHeight=parameters(3);
stepStart=parameters(4);

integral= -(exp(-((stepStart-xStart)^2)/(2*(sigma^2)))-exp(-((stepStart-xEnd)^2)/(2*(sigma^2))))*sqrt(2/pi)*sigma;

integral= integral +(exp(-((stepEnd-xStart)^2)/(2*(sigma^2)))-exp(-((stepEnd-xEnd)^2)/(2*(sigma^2))))*sqrt(2/pi)*sigma;

integral= integral -(stepStart-xStart)*erf((stepStart-xStart)/(sqrt(2)*sigma))+(stepEnd-xStart)*erf((stepEnd-xStart)/(sqrt(2)*sigma));

integral= integral +(stepStart-xEnd)*erf((stepStart-xEnd)/(sqrt(2)*sigma))-(stepEnd-xEnd)*erf((stepEnd-xEnd)/(sqrt(2)*sigma));

integral= integral*(1/2)*stepHeight;

end