
% This is the impedance function we're analyzing
Z_num = [1, 0, 1];
Z_den = [1, 0, 3, 0];
admittance = false;

% For the first stage, we use Cauer's 2nd form
[k1, tn1, td1] = cauer2el(Z_num, Z_den);
admittance = ~admittance;


% For the second stage, we use Cauer's 1st form
%
	% We switch to admittance (flip numerator, denominator terms) because 1st
	% form requires higher order numerator.
[k2, tn2, td2] = cauer1el(tn1, td1);
admittance = ~admittance;
if iselement(tn2, td2)
	disp("Element!");
end
