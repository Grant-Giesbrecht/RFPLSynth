function tf = iselement(num, den, varargin)

	% Process optional inputs
	expectedFormats = {'FOSTER', 'CAUER'};
	expectedPositions = {'NUM', 'DEN', 'ANY'}; % Valid for Cauer only

	p = inputParser;
	p.addParameter('Format', 'CAUER', @(x) any(validatestring(upper(x),expectedFormats)) );
	p.addParameter('Position', 'ANY', @(x) any(validatestring(upper(x),expectedPositions)) );
	p.parse(varargin{:});

	% Check if looking for Foster or Cauer format of element
	if strcmpi(p.Results.Format, 'FOSTER'); %==== Format is Foster ========

		% Create polynomial objects for safer access
		np = Polynomial(0);
		dp = Polynomial(0);
		np.setVec(num);
		dp.setVec(den);

		% Check that numerator order is correct
		if np.order() ~= 1
			tf = false;
			return;
		end

		% Check that denominator order is correct
		if dp.order() ~= 2 && dp.order() ~= 0
			tf = false;
			return;
		end
		
		% Check that no constant in numerator
		if np.get(0) ~= 0
			tf = false;
			return;
		end
		
		% Check that no order-1 term in denominator
		if dp.get(1) ~= 0
			tf = false;
			return;
		end

		tf = true;
		return;

	else %======================================= Format is Cauer =========
		% Indicates 's' can be, ie. numerator vs denomenator.
		% 0 = either
		% 1 = numerator
		% 2 = denominator
		position = 0;

		% Handle optional position argument
		if strcmpi(p.Results.Position, "NUM")
			position = 1;
		elseif strcmpi(p.Results.Position, "DEN")
			position = 2;
		elseif strcmpi(p.Results.Position, "ANY")
			position = 0;
		elseif ~strcmp(p.Results.Position, "")
			warning(strcat("Option '", string(p.Results.Position), "' unrecognized - ignoring position option."));
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
	end %==================== End Format is Cauer =========================

end
