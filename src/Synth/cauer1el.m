function [k, Tn, Td] = cauer1el(num, den)
% CAUER1 
%
%		   num              1
%	Z(s) = ---  =  k*s + ------		(Tn, Td would be passed to CAUER1 as
%		   den            Tn/Td      num and den, respectively).
%
	% Perform polynomial division
	[quot, rem] = deconv(num, den);
	
	% Save results to appropriate outputs
	k = quot(1);
	Tn = den;
	Td = rem;
	
	
	if length(find(Tn==0)) == length(Tn) % Check if Tn is only zeros
		Tn = 0; 
	else
		% Trim zeros from Tn
		idx = find(Tn, 1, 'first');
		Tn = Tn(idx:end);
	end
	
	if length(find(Td==0)) == length(Td) % Check if Td is only zeros
		Td = 0;
	else
		% Trim zeros from Td
		idx = find(Td, 1, 'first');
		Td = Td(idx:end);
	end
	
end