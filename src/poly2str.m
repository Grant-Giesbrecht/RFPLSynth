function strout = poly2str(p, xstr)
	
	if p.iszero()
		strout = "0";
		return;
	end

	if ~exist('xstr','var')
		xstr = "x";
	end

	strout = "";

	for ord = p.order():-1:0
		
		% If coefficient is not zero...
		if p.get(ord) ~= 0
		
			% Check if show '+' or '-'
			if ord == p.order()
				val_str = num2str(p.get(ord));
			elseif p.get(ord) < 0
				strout = strcat(strout, " - ");
				val_str = num2str(abs(p.get(ord)));
			else
				strout = strcat(strout, " + ");
				val_str = num2str(abs(p.get(ord)));
			end

			% Add value to string
			strout = strcat(strout, val_str);
			
			% Check if 'x' should be shown
			if ord > 1 % x^ord will be shown
				strout = strcat( strout, xstr, "^", num2str(ord) );
			elseif ord == 1
				strout = strcat( strout, xstr);
			end
		end
	end
end