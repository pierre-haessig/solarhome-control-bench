function out_data = reArrangeMat(varargin)
%**********************************************************************
%% HOME_SIM_MPC || Auxiliary function reArrangeMat
% Version: 1.1
% Required functions: None
% 
% Inputs : 
% The first input must be the prediction horizon (input_1 = horiz)
% The second input up to the last(N) are the matrices or  vectors 
% to be rearranged. The function constructs an output as the following. 
%
% Output =[   input_2(1,:);
%             input_3(1,:);
%             ............;
%             input_N(1,:);
%          ------------------
%             input_2(2,:);
%             input_3(2,:);
%             ............;
%             input_N(2,:);
%          ------------------
%             ............;
%             ............;
%             ............;
%             ............;
%          ------------------
%           input_2(horiz,:);
%           input_3(horiz,:); 
%           ................;
%           input_N(horiz,:) ];
% 
%
% Author : Jesse - James PRINCE A. || May 2018 
%**********************************************************************

 
N_inp = nargin; % Get the number of input given to the function;
horiz = varargin{1}; % Get the data within the first input which is the 
%prediction horizon;

cur_row = 1;% Current row. Variable Used to go from line 1 up to last line 
% of every input

for i=1:N_inp-1:horiz*(N_inp-1)
    
    cur_inp = 2; % Current input number % do not forget that we are using 
    %data from input_2 to input_N
    
    for k=i:i+N_inp-2
        var1 = varargin{cur_inp};
        out_data(k,:) = var1(cur_row,:);

        cur_inp = cur_inp+1;
    end
    
    cur_row = cur_row+1;
end
end
