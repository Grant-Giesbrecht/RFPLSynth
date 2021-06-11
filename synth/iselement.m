function tf = iselement(num, den, position_opt)

	% Handle optional argument 'position_opt'
	if ~exist('position_opt', 'var')
		position_opt = "";
	end
	
	% Indicates 's' can be, ie. numerator vs denomenator.
	% 0 = either
	% 1 = numerator
	% 2 = denominator
	position = 0;
	
	% Handle optional position argument
	if strcmpi(position_opt, "NUM")
		position = 1;
	elseif strcmpi(position_opt, "DEN")
		position = 2;
	elseif ~strcmp(position_opt, "")
		warning(strcat("Option '", string(position_opt), "' unrecognized - ignoring position option."));
	end
	
	% Trim zeros from numerator poly vector
	idx = find(num, 1, 'first');
	num = num(idx:end);
	
	% Trim zeros from denominator poly vector
	idx = find(den, 1, 'first');
	den = den(idx:end);

	% If position is set to either, change that now to numerator (1) or
	% denominator (2) by checking the order of the numerator
	if position == 0
			
		% Check numerator length
		if length(num) == 2 % Numerator is order 1, set position to numerator
			position = 1;
		elseif length(num) == 1 % Numerator is order 0, set position to denominator
			position = 2;
		else % Numerator is not order 1 or 0, not element
			tf = false;
			return;
		end
	end
	
	% Check if numerator and denominator comprise an 'element'
	tf = true;
	switch position
			
		case 1 % Numerator can have 's'
			
			% Verify denominator is only a constant
			if length(den) ~= 1
				tf = false;
				return;
			end
			
			% Verify numerator is order 1
			if length(num) ~= 2
				tf = false;
				return;
			end
			
			% Verify no constant is added to 's' in numerator
			if num(end) ~= 0
				tf = false;
				return;
			end
			
		case 2 % Denominator can have 's'
			
			% Verify numerator is only a constant
			if length(num) ~= 1
				tf = false;
				return;
			end
			
			% Verify denominator is order 1
			if length(den) ~= 2
				tf = false;
				return;
			end
			
			% Verify no constant is added to 's' in denominator
			if den(end) ~= 0
				tf = false;
				return;
			end
			
		otherwise
			error(strcat("Error occured in 'iselement.m'. Unrecognized position value (", num2str(position) ,")"));
	end
	
end
























