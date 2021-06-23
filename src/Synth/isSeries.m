function tf = isSeries(ce1, ce2)

	tf = false;

	% 1-ce1-2 -> 1-ce2-2
	if ce1.nodes(1) ~= ce2.nodes(2) && ce1.nodes(2) == ce2.nodes(1)
		tf = true;
		return;
	end
	
	% 2-ce1-1 -> 1-ce2-2
	if ce1.nodes(2) ~= ce2.nodes(2) && ce1.nodes(1) == ce2.nodes(1)
		tf = true;
		return;
	end
	
	% 1-ce1-2 -> 2-ce2-1
	if ce1.nodes(1) ~= ce2.nodes(1) && ce1.nodes(2) == ce2.nodes(2)
		tf = true;
		return;
	end
	
	% 2-ce1-1 -> 2-ce2-1
	if ce1.nodes(2) ~= ce2.nodes(1) && ce1.nodes(1) == ce2.nodes(2)
		tf = true;
		return;
	end

end