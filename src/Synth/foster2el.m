function [L, C, Tn, Td] = foster2el(num, den)
%
%
%          num           C*s         Tn
%   Z(s) = ---  =  ------------- + ------      (Tn, Td would be passed to FOSTER as
%          den      L*C*s^2 + 1       Td      num and den, respectively).
%

	% Is exactly the same as foster1el, just L and C are switched
	[C, L, Tn, Td] = foster1el(num, den);


end
