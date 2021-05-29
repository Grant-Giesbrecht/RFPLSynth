function s_xy = getParam(x, y, f, SParam)

	f_idx = find(SParam.Frequencies == f);
	if isempty(f_idx)
		s_xy = [];
		return;
	end

	s_xy = SParam.Parameters(x, y, f_idx);
	
end