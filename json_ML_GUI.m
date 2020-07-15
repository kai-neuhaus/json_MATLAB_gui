function params = json_GUI(varargin)
% USAGE:
%
%     params = json_GUI('params','parameters.json');
%
% opens a dialog with parameters defined in 'parameters.json'.
% The return parameter 'params' contains all parameters that were modified in the GUI.
% Call 'params = construct_params( params );' to expose all parameters into the workspace.
% The GUI also stores the modifications back into the 'parameters.json'.
%
% If you do not have any parameter file you can create one by calling
%     json_GUI('init','new_params.json');
% and add parameters as required into the JSON file.
%
% If you need to convert a json-file with parameters into an MATLAB file call
%     JSON_to_ml('json_params.json');
% 
%
% Created: Kai Neuhaus 
% Date: 03.05.2020
% Modified: Kai Neuhaus 
% Date: 28.06.2020 
%   improve GUI element position

    if nargin > 0 && strcmp(varargin{1}, 'init')
        if nargin < 2
            error('Please give a file-name for initialization:\n json_GUI(''init'', <fname>).');
        end
        create_json_template(varargin{2});
        return; % only this action is valid then return

    elseif nargin > 0 && strcmp(varargin{1}, 'params')
        if nargin < 1
            error('Please give the json-file-name to read from: json_GUI(''params'', <fname>).');
        end
        json_str_b = importdata(varargin{2});
        json_str_b = [json_str_b{:}]; % make a one line string.
        params_in = jsondecode(json_str_b);
        params = parameter_dialog( params_in, varargin{2} );
        
        return; % only this action is valid then return.
    
    elseif nargin == 0 % Give guidance to create a new file or how to use this function.
        d = dialog('name','json_GUI Help','position',[300,300,500,350]);
        txt = uicontrol('Parent',d,...
            'Style','text',...
            'HorizontalAlignment','Left',...
            'Position',[10,20,500,280],...
            'String',['This GUI is managing all parameters in a json file.',newline,...
            'You can create a new json template file by calling this function like:',newline,newline,...
            '    json_GUI(''init'',<fname.json>)',newline,newline,...
            'which creates a new json template.',newline,...
            'Then you can test the GUI by calling',newline,newline,...
            '    json_GUI(''params'',<fname.json>)',newline,newline,...
            'to load the dialog.',newline,...
            'Then any changes made in the dialog are written into the json file.',newline,newline,...
            'If the GUI is called in your script it returns params-structure from the parameters modified.',newline,...
            'The params-structur can then be used like',newline,...
            '    params.name',newline,...
            'which would just return the value or you can assign a new value.',newline,...
            'Of course assigning a new value in the middle of the code can cause inconsistency and should not be done.']);
        b = uicontrol('Parent',d,'String','OK','Style','pushbutton','position',[180,10,50,40],'callback',@close_help_dialog,'UserData',d);
        return;
    end
    

end

function close_help_dialog(src,evnt)
    % close help dialog
    delete(src.UserData);
end


function params = parameter_dialog( params_in, json_fname )
    % Well here we have to use global if we do not have access yet ot userData.
    % But maybe this can also be improved at some time.
    global is_close_request;
    is_close_request = false;
    global params_from_submit_button_pressed;
    params_from_submit_button_pressed = [];
    
% see more here https://uk.mathworks.com/matlabcentral/answers/502990-create-a-input-dialog-with-text-entry-and-also-drop-down-menu
    json_params_out = params_in;
    screensize      = get(0,'screensize');

    % Create a new composite type by defining a new composite function and add it here to composites.
    % composites.YourC = @YourC_function;
    composites.Double = @Entry_Double_composite;
    composites.Path   = @Entry_Path_composite;
    composites.Bool   = @Entry_Bool_composite;
    composites.Position = @Dummy_Position_composite;
    composites.Dialog = @Dummy_Dialog_composite;
    
    % Make a string of all composite types
    composite_list = fieldnames(composites);
    composite_strings = regexprep(composite_list,'(.*)','$1, '); %insert comma after bracket '()' expression
    known_types = sprintf('%s',composite_strings{:});


    % add params into gui composites and show them
    for i = 1:length(params_in)
        if contains('Dialog', params_in{i}.type)
            fprintf('%s\n',mat2str(screensize));
            dlg_x = params_in{i}.X_start;
            dlg_y = params_in{i}.Y_start;
            y_scale = params_in{i}.Y_scale;
            x_scale = params_in{i}.X_scale;
            hfig=figure('position',screensize .* [1,1,x_scale,y_scale] + [screensize(3:4) .* [dlg_x,dlg_y],0,0]); %[100,100,600,600]); % 'CloseRequestFcn',@close_req_fun,'menu','none');
            % It could be scrollable using uipanel. If somebody needs this and I get paid then I can do it.
            set(hfig,'menu','none','NumberTitle','off','name','json Parameter Dialog','CloseRequestFcn',@close_req_fun);

            % fine control of size of GUI elements
%             y_shift_top = 0.99; 
%             y_height = 0.028;
%             x_pos = 0.0;
%             y_pos = y_shift_top;
            y_height = params_in{i}.Item_height;
            x_pos = params_in{i}.Item_X_start;
            y_pos = params_in{i}.Item_Y_start;


        elseif contains('Position', params_in{i}.type)
            x_offset = params_in{i}.X;
            y_offset = params_in{i}.Y;
            x_pos = x_offset;
            y_pos = y_offset;
        else
            y_pos = y_pos - y_height; % subtract to move top to bottom
            if ~contains(composite_list, params_in{i}.type)
                error('\nParameter type ''%s'' not found.\nKnown types are %s.',params_in{i}.type, known_types(1:end-2) );
            end
            % call composite to construct the uicontrol - meaning the item is added to the dialog.
            % keep the uicontrol in json_params for retrieving values.
            json_params_out{i}.composite = ...
                composites.(params_in{i}.type)(hfig, params_in{i}, x_pos, y_pos, 1/y_scale);
        end
    end
    
    submit_button_uicontrol(hfig,json_params_out,json_fname);
    uiwait(hfig); % wait until dialog is closed

%     get(hfig,'UserData') % object is now deleted


    if ~is_close_request
        params = params_from_submit_button_pressed;
    else 
        error('Stop.');
    end
    % read back data from dialog and assign into params to return

%     delete(hfig);

end


function close_req_fun(src,~)
    global is_close_request;
    is_close_request = true;
    fprintf('close request\n');
%     close('all');
    delete(src);
end

function uiedit = Entry_Bool_composite(h, param, x_pos, y_pos, scale )
% This is a Boolean composite allowing to enter True or False
    height          = 0.02*scale;
    text_width      = 0.15;
    field_width     = 0.15;
    spacing         = 0.01;
    uitext = uicontrol('Style','Text', ...
        'String',param.name, ... 
        'HorizontalAlignment','Right', ...        
        'TooltipString',['No info.'], ...
        'Parent',h, ... 
        'Units','normalized', ...
        'position', [x_pos, y_pos, text_width, height]);                
    uiedit = uicontrol('Style','CheckBox', ...
        'String','', ... 
        'Value', param.value, ... 
        'TooltipString',['No info.'], ...
        'Parent',h, ... 
        'Units','normalized', ...
        'position', [x_pos+text_width+spacing, y_pos, field_width, height]);
    if isfield(param,'help')
        uitext.TooltipString = param.help;
    end

end

function uiedit = Entry_Double_composite(h, param, x_pos, y_pos, scale )
% This is a number composite allowing to enter a number
    height          = 0.02*scale;
    text_width      = 0.15;
    field_width     = 0.15;
    unit_width      = 0.05;
    spacing         = 0.01;
    uitext = uicontrol('Style','Text', ...
        'String',param.name, ... 
        'HorizontalAlignment','Right', ...        
        'TooltipString','No info.', ...
        'Parent',h, ... 
        'Units','normalized', ...
        'position', [x_pos, y_pos, text_width, height]); 
    uiedit = uicontrol('Style','Edit', ...
        'String',num2str(param.value), ... 
        'HorizontalAlignment','Left', ...        
        'TooltipString','No info.', ...
        'Parent',h, ... 
        'Units','normalized', ...
        'position', [x_pos+text_width+spacing, y_pos, field_width, height]);
    if any(contains(fieldnames(param),'unit')) % if a unit was given
        uicontrol('Style','Text', ...
            'String',param.unit, ... 
            'HorizontalAlignment','Right', ...        
            'TooltipString','No info.', ...
            'Parent',h, ... 
            'Units','normalized', ...
            'position', [x_pos+text_width+spacing+field_width+spacing, y_pos, unit_width, height]); 
    end
    if isfield(param,'help')
        uitext.TooltipString = param.help;
        uiedit.TooltipString = param.help;
    end

end

function userData = Entry_Path_composite(h, param, x_pos, y_pos, scale)
% This is a path composite that allows to select a path and filename
    height          = 0.02*scale;
    text_width      = 0.15;
    path1_width     = 0.15;
    path2_width     = 0.40;
    button_width    = 0.1;
    spacing         = 0.01;
    uicontrol('Style','Text', ...
        'String','Filename / Path', ... 
        'HorizontalAlignment','Right', ...
        'TooltipString','Filename / Path', ...
        'Parent',h, ... 
        'Units','normalized', ...
        'position', [x_pos, y_pos, text_width, height]);        
    fnameui = uicontrol('Style','Edit', ...
        'String',param.value.fileName, ...
        'HorizontalAlignment','Left', ...        
        'TooltipString',param.value.fileName, ...
        'Parent',h, ... 
        'Units','normalized', ...
        'position', [x_pos+text_width+spacing, y_pos, path1_width, height]);   
    % On windows jsondecode removes the escapes but as we need them we put them back
    if ispc > 0
        path_str = strrep(param.value.fileBase,'\','\\');
    else
        path_str = param.value.fileBase;
    end
    pathui = uicontrol('Style','Edit', ...
        'String',path_str, ...
        'HorizontalAlignment','Left', ...        
        'TooltipString',path_str, ...
        'Parent',h, ... 
        'Units','normalized', ...
        'position', [x_pos+text_width+spacing+path1_width, y_pos, path2_width, height]); 
    userData.pathui = pathui;
    userData.fnameui = fnameui;
    uicontrol('Style','Pushbutton', ...
        'String','Select', ...
        'TooltipString',['Select a new file.'], ...
        'Parent',h, ... 
        'Units','normalized', ...
        'position', [x_pos+text_width+spacing+path1_width+spacing+path2_width+spacing, y_pos, button_width, height], ...
        'callback',@Entry_Path_composite_select_new_file, ...
        'UserData',userData);
end

function userData = Dummy_Position_composite(h, param, x_pos, y_pos, scale)
% This does nothing but we need this to keep the composite handling consistent
    userData = [];
end

function userData = Dummy_Dialog_composite(h, param, x_pos, y_pos, scale)
% This does nothing but we need this to keep the composite handling consistent
    userData = [];
end


function Entry_Path_composite_select_new_file(src, event)

    [n,p] = uigetfile('*.mat','Vienna data file');
    if any(n) && any(p)
        % Convert path separators for windows platforms like '\' --> '\\'
        if ispc > 0
            p = strrep(p,'\','\\');
            src.UserData.pathui.String = p;
        else
            src.UserData.pathui.String = p; 
        end
        src.UserData.pathui.TooltipString = p;
        src.UserData.fnameui.String = n; 
        src.UserData.fnameui.TooltipString = n;
    end
end

function submit_button_uicontrol(h,json_params_out,json_fname)
    x_start         = 0.80;
    y_start         = 0.05;
    height          = 0.05;
    text_width      = 0.15;
    path1_width     = 0.25;
    path2_width     = 0.30;
    button_width    = 0.1;
    spacing         = 0.01;
    userdata.h      = h;
    userdata.json_params_out = json_params_out;
    userdata.json_fname = json_fname;
    uicontrol('Style','Pushbutton', ...
        'String','Submit', ... 
        'TooltipString','Write data to json-file.', ...
        'Parent',h, ... 
        'Units','normalized', ...
        'position', [x_start, y_start, text_width, height],...
        'callback',@submit_button_pressed,...
        'userdata',userdata);

end

function submit_button_pressed(src,~)
    global params_from_submit_button_pressed; % this is what is returned to 'params'
    json_params_out = src.UserData.json_params_out;

    try
        % try to create json output from dialog data
        for i=1:length(json_params_out) % read all uicontrol data back
%             fprintf('%s\n',json_params_out{i}.name);
            if strcmp(json_params_out{i}.type,'Position') || strcmp(json_params_out{i}.type,'Dialog') 
                json_params_out{i}.composite = 'Dummy'; % The GUI has none so we create a dummy here.
            elseif strcmp(json_params_out{i}.type,'Path')
                json_params_out{i}.value.fileBase = json_params_out{i}.composite.pathui.String;
                json_params_out{i}.value.fileName = json_params_out{i}.composite.fnameui.String;
            elseif strcmp(json_params_out{i}.type,'Bool')
                json_params_out{i}.value = json_params_out{i}.composite.Value;
            elseif strcmp(json_params_out{i}.value,'auto')
                json_params_out{i}.value = json_params_out{i}.composite.String;
            elseif ~isnumeric(json_params_out{i}.value) && ... % assuming it is an array [ ... ]
                    isnumeric(eval(json_params_out{i}.value)) && numel(eval(json_params_out{i}.value)) > 1
                json_params_out{i}.value = mat2str(eval(json_params_out{i}.composite.String));
            else
                json_params_out{i}.value = eval(json_params_out{i}.composite.String);
            end
            json_params_out{i} = rmfield(json_params_out{i},'composite'); % remove composite for json output
        end
    catch exception
        fprintf('Please copy this error:\n\n%s\n\n',exception.message);
        for i = 1:length(exception.stack)
            fprintf('%s: line=%i\n',exception.stack(i).name, exception.stack(i).line);
        end
        estr = split(exception.message,' ');
        
        for i=1:length(estr) % make the error string fit into the text ui
            if mod(i,8) == 0
                estr{i} = [estr{i},' ',newline];
            else 
                estr{i} = [estr{i},' '];
            end
        end
        
        d = dialog('name','ERROR json_GUI ...','position',[300,300,400,300]);
        errui = uicontrol('Parent',d,...
            'Style','text',...
            'BackgroundColor','Yellow',...
            'HorizontalAlignment','Left',...
            'Position',[10,0,400,300],...
            'String',[newline,'You probably try to use an invalid value in the GUI.',newline,newline,...
            'Please consider only:',newline,...
            '  Numbers',newline,...
            '  Arrays (like ''[1, 2, 3]''',newline,...
            '  ''auto'' string',newline,...
            'is valid.',newline,newline,...
            'This GUI does not a complete sanity check for all variables and',newline,...
            'you need to assure yourself that all entries make sense.',newline,newline,...
            'Original Error message was:',newline,newline,...
            estr{:}
            ]);
        cui = uicontrol('Parent',d,'String','CANCEL','Style','pushbutton','position',[180,10,50,20],'callback',@close_help_dialog,'UserData',d);
        delete(src.UserData.h);
        return;
 
    end
    
    json_str = jsonencode(json_params_out);
    json_str = replace(json_str,'},','},\n');
    json_str = replace(json_str,',',',\n');

    fid = fopen(src.UserData.json_fname,'w');
    fprintf(fid,json_str);
    fclose(fid);

    % Finally create the data structure with all params to be returned to the caller.
    % Meaning these are the parameters used in the main function.
    params_out = [];
    for i = 1:length(json_params_out)
        
        if strcmp(json_params_out{i}.type,'Double') && ...
                ischar(json_params_out{i}.value) && any(regexp(json_params_out{i}.value,'\[.*?\]'))
        %TODO: array assignments like = [1 2 3] are convenient but break parameter assignment. 
            fieldname_array_assign = json_params_out{i}.name;
            value_str = json_params_out{i}.value;
            params_out.(fieldname_array_assign) = eval(value_str);            
        elseif strcmp(json_params_out{i}.type,'Double') && ... 
                ~ischar(json_params_out{i}.value) && any(regexp(json_params_out{i}.name,'(.)')) 
        %TODO: this is only required to test for if we have such singular array assignments.
            fieldname_array_assign = json_params_out{i}.name;
            value = json_params_out{i}.value;
            eval(['params_out.',fieldname_array_assign,'=',num2str(value),';']);
        elseif strcmp(json_params_out{i}.type,'Double') && ...
                ischar(json_params_out{i}.value) && ~any(regexp(json_params_out{i}.name,'(.)')) 
            fieldname_array_assign = json_params_out{i}.name;
            value = json_params_out{i}.value;
            eval(['params_out.',fieldname_array_assign,'=',value,';']);            
        elseif strcmp(json_params_out{i}.type, 'Path')
            params_out.(json_params_out{i}.name).fileName = json_params_out{i}.value.fileName;
            params_out.(json_params_out{i}.name).fileBase = json_params_out{i}.value.fileBase;
            %to stay backwards compatible
            params_out.fileName = json_params_out{i}.value.fileName;
            params_out.fileBase = json_params_out{i}.value.fileBase;
        elseif strcmp(json_params_out{i}.type, 'Dialog')
            params_out.Dialog.X_start = json_params_out{i}.X_start;
            params_out.Dialog.Y_start = json_params_out{i}.Y_start;
            params_out.Dialog.X_scale = json_params_out{i}.X_scale;
            params_out.Dialog.Y_scale = json_params_out{i}.Y_scale;            
            params_out.Dialog.Item_height = json_params_out{i}.Item_height;            
            params_out.Dialog.Item_X_start = json_params_out{i}.Item_Y_start;            
            params_out.Dialog.Item_Y_start = json_params_out{i}.Item_Y_start;            
        elseif strcmp(json_params_out{i}.type, 'Position')
            params_out.Dialog.X = json_params_out{i}.X;
            params_out.Dialog.Y = json_params_out{i}.Y;
        else
            params_out.(json_params_out{i}.name) = json_params_out{i}.value;
        end
    end

    params_from_submit_button_pressed = params_out;
%     src.UserData.h.UserData = json_params_out;
%     get(src.UserData.h,'children')
%     close(src.UserData.h); % causes close request but this is our error.
    delete(src.UserData.h); % close dialog

end

function create_json_template(json_fname)
% This could be generated from the composite definitions.
% For now we perform a plain text write.

    json_template = ['[\n',...
     '{\n',...
     '"type":"Dialog",',...
     '"name":"dialog_size_position",',...
     '"X_start":0.05,',...
     '"Y_start":0.05,',...
     '"X_scale":0.5,',...
     '"Y_scale":0.75,',...
     '"Item_height":0.028,',...
     '"Item_X_start":0,',...
     '"Item_Y_start":0.99,',...
     '"help":"Position and size of the Dialog in fractions of screensize. Size fraction is added to start.Item_height is the fraction of the height of each single field.Item_X/Y_start is the fraction to start placing items into the dialog."',...
     '},\n',...
     '\n',...
    '{\n',...
    '"name":"URI",',...
    '"type":"Path",',...
    '"value":{"fileName":"raw data.mat",',... 
    '"fileBase":"/Users/test/"}',...
    '},',...
    '\n',...
    '{\n',...
    '"name":"wavelength",',...
    '"value":1300,',...
    '"help":"Nanometer",',...
    '"type":"Double"\n',...
    '},',...
    '',...
    '{\n"name":"length",',...
    '"value":100,',...
    '"help":"Meter",',...
    '"type":"Double"\n},',...
    '',...
    '{"type":"Position",',...
    '"name":"pos_offset",',...
    '"help":"Move subsequent parameter elements in the GUI by some offset X and Y",',...
    '"X":0.4,',...
    '"Y":0.92},',...
    '',...
    '{\n"name":"Process",',...
    '"value":false,',...
    '"help":"Do you want to process?",',...
    '"type":"Bool"\n}\n',...
    ']'];
    json_str = json_template;
    json_str = replace(json_str,'},','},\n');
    json_str = replace(json_str,',',',\n');

    fid = fopen(json_fname,'w');
    fprintf(fid,json_str);
    fclose(fid);
end
