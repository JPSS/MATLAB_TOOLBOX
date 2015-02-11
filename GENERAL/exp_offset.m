function y = exp_offset(x,amplitude,exponentialFactor,offset)
%% exponential function with constant offset y=amplitude*exp(exponentialFactor*x)+offset
%   x
%   amplitude = amplitude of exponential function
%   exponentialFactor = exponential factor of exponential function
%   offset = constant offset

y=amplitude*exp(exponentialFactor*x)+offset;