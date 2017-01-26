function obj = addCollocationConstraint(obj, phase)
    % Add direct collocation equations as a set of equality constraints 
    %    %
    % Parameters:
    % phase: the index of the phase (domain) @type integer
    % model: the rigid body model of the robot @type RigidBodyModel
    
    generic_funcs = obj.Funcs.Generic;
    
    phase_idx = getPhaseIndex(obj, phase);
    phase_info = obj.Phase{phase_idx};
    
    
    n_node = phase_info.NumNode;
    var_table= phase_info.OptVarTable;
    col_names = phase_info.ConstrTable.Properties.VariableNames;
    
    n_dof = obj.Model.nDof;
    
    err_bound = obj.Options.EqualityBoundRelaxFactor;
    
    switch obj.Options.CollocationScheme
        case 'HermiteSimpson' % Hermite-Simpson Scheme
            % collocation constraints are enforced at all interior nodes
            node_list = 2:2:n_node-1;
            
            % always create a cell array with the length of ''num_node'' as
            % place holder
            intPos = repmat({{}},1, n_node);
            intVel = repmat({{}},1, n_node);
            midPos = repmat({{}},1, n_node);
            midVel = repmat({{}},1, n_node);
            for i=node_list
                if obj.Options.DistributeParamWeights
                    node_param = i;
                else
                    node_param = 1;
                end
                
                % Qn - Qe - dt(dQn + 4dQm + dQe)/6
                intPos{i} = {NlpFunction('Name','intPos',...
                    'Dimension',n_dof, 'Type', 'nonlinear',...
                    'lb',-err_bound,'ub',err_bound,'DepVariables',...
                    {{var_table{'T',node_param}{1},...
                    var_table{'Qe',i-1}{1},var_table{'dQe',i-1}{1},...
                    var_table{'dQe',i}{1},...
                    var_table{'Qe',i+1}{1},var_table{'dQe',i+1}{1}}},...
                    'AuxData', n_node,...
                    'Funcs', generic_funcs.intPosHS.Funcs)};
                
                % dQn - dQe - dt(ddQn + 4ddQm + ddQe)/6
                intVel{i} = {NlpFunction('Name','intVel',...
                    'Dimension',n_dof, 'Type', 'nonlinear',...
                    'lb',-err_bound,'ub',err_bound,'DepVariables',...
                    {{var_table{'T',node_param}{1},...
                    var_table{'dQe',i-1}{1},var_table{'ddQe',i-1}{1},...
                    var_table{'ddQe',i}{1},...
                    var_table{'dQe',i+1}{1},var_table{'ddQe',i+1}{1}}},...
                    'AuxData', n_node,...
                    'Funcs', generic_funcs.intVelHS.Funcs)};
                
                % Qm -(Qe+Qn)/2 - dt(dQe-dQn)/8
                midPos{i} = {NlpFunction('Name','midPos',...
                    'Dimension',n_dof, 'Type', 'nonlinear',...
                    'lb',-err_bound,'ub',err_bound, 'DepVariables',...
                    {{var_table{'T',node_param}{1},...
                    var_table{'Qe',i-1}{1},var_table{'dQe',i-1}{1},...
                    var_table{'Qe',i}{1},...
                    var_table{'Qe',i+1}{1},var_table{'dQe',i+1}{1}}},...
                    'AuxData', n_node,...
                    'Funcs', generic_funcs.midPosHS.Funcs)};
                
                % dQm -(dQe+dQn)/2 - dt(ddQe-ddQn)/8
                midVel{i} = {NlpFunction('Name','midVel',...
                    'Dimension',n_dof, 'Type', 'nonlinear',...
                    'lb',-err_bound,'ub',err_bound,'DepVariables',...
                    {{var_table{'T',node_param}{1},...
                    var_table{'dQe',i-1}{1},var_table{'ddQe',i-1}{1},...
                    var_table{'dQe',i}{1},...
                    var_table{'dQe',i+1}{1},var_table{'ddQe',i+1}{1}}},...
                    'AuxData', n_node,...
                    'Funcs', generic_funcs.midVelHS.Funcs)};
                
                
            end
            
            % add to the constraints table
            obj.Phase{phase_idx}.ConstrTable = [...
                obj.Phase{phase_idx}.ConstrTable;...
                cell2table(intPos,'RowNames',{'intPos'},'VariableNames',col_names);...
                cell2table(intVel,'RowNames',{'intVel'},'VariableNames',col_names);...
                cell2table(midPos,'RowNames',{'midPos'},'VariableNames',col_names);...
                cell2table(midVel,'RowNames',{'midVel'},'VariableNames',col_names)];
        case 'Trapzoidal'
            % collocation constraints are enforced at interior nodes except
            % the last node
            node_list = 1:1:n_node-1;
            
            % always create a cell array with the length of ''num_node'' as
            % place holder
            intPos = repmat({{}},1, n_node);
            intVel = repmat({{}},1, n_node);
            for i=node_list
                if obj.Options.DistributeParamWeights
                    node_param = i;
                else
                    node_param = 1;
                end
                
                % Qn - Qe - dt(dQn+dQe)/2
                intPos{i} = {NlpFunction('Name','intPos',...
                    'Dimension',n_dof, 'Type', 'nonlinear',...
                    'lb',-err_bound,'ub',err_bound,'DepVariables',...
                    {{var_table{'T',node_param}{1},...
                    var_table{'Qe',i}{1},var_table{'dQe',i}{1},...
                    var_table{'Qe',i+1}{1},var_table{'dQe',i+1}{1}}},...
                    'AuxData', n_node,...
                    'Funcs', generic_funcs.intPosTZ.Funcs)};
                
                % dQn - dQe - dt(ddQn+ddQe)/2
                intVel{i} = {NlpFunction('Name','intVel',...
                    'Dimension',n_dof, 'Type', 'nonlinear',...
                    'lb',-err_bound,'ub',err_bound,'DepVariables',...
                    {{var_table{'T',node_param}{1},...
                    var_table{'dQe',i}{1},var_table{'ddQe',i}{1},...
                    var_table{'dQe',i+1}{1},var_table{'ddQe',i+1}{1}}},...
                    'AuxData', n_node,...
                    'Funcs', generic_funcs.intVelTZ.Funcs)};
                
                
            end
            
            
            
            % add to the constraints table
            obj.Phase{phase_idx}.ConstrTable = [...
                obj.Phase{phase_idx}.ConstrTable;...
                cell2table(intPos,'RowNames',{'intPos'},'VariableNames',col_names);...
                cell2table(intVel,'RowNames',{'intVel'},'VariableNames',col_names)];
        case 'PseudoSpectral'
            node_list = 1:1:n_node;
            %| @todo implement pseudospectral method
            error('Not yet implementeded.');
        otherwise
            error('Unsupported collocation scheme');
    end
    
    
    
end