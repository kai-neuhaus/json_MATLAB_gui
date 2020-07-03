function JSON_to_ml( json_file )
% Convert a JSON file into a MATLAB file.
%
% USAGE:
%   export_params( json_file )
%
% Created: Kai Neuhaus
% Date: 28.06.2020
% Modified:
% Date:

if nargin == 0
    error('Please provide a file name to the json file to convert.');
end

json_str_b = importdata(json_file);
json_str_b = [json_str_b{:}]; % make a one line string.
params_in = jsondecode(json_str_b);

json_file_sans_ext = split(json_file,'.json'); % remove json extension
ml_file = [json_file_sans_ext{1}, '_params.m'];
if exist(ml_file) > 0
    error('File %s exist. I do not overwrite. Please chose another name.',ml_file); 
end
fid = fopen(ml_file,'w');
boolstr = {'false','true'};
for i=1:length(params_in)
%     params_in{i}
    if strcmp(params_in{i}.type,'Path')
        param_names = fieldnames(params_in{i}.value);
        fprintf(fid,'%s = ''%s'';\n',param_names{1},params_in{i}.value.(param_names{1}));
        fprintf(fid,'%s = ''%s'';\n',param_names{2},params_in{i}.value.(param_names{2}));
    elseif strcmp(params_in{i}.type,'Double')
        if ~isnumeric(params_in{i}.value) && strcmp(params_in{i}.value,'auto')
            fprintf(fid,'%s = ''auto'';\n',params_in{i}.name);
        elseif any(regexp(mat2str(params_in{i}.value),'\[.*?\]')) % is matrix?
            fprintf(fid,'%s = %s;\n',params_in{i}.name,strrep(mat2str(params_in{i}.value),'''',''));
        else
            fprintf(fid,'%s = %d;\n',params_in{i}.name,params_in{i}.value);
        end
    elseif strcmp(params_in{i}.type,'Bool')
        fprintf(fid,'%s = %s;\n',params_in{i}.name, boolstr{params_in{i}.value+1});
    end
    
end
fclose(fid);
end