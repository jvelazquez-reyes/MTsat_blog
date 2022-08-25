%% Get MTon, MToff and T1w varying MT pulse shape and T1 value
% Simulate complete qMT-SPGR protocol
Model_qmtSPGR = qmt_spgr;
Model_qmtSPGR.Prot.MTdata.Mat = [490, 1200]; % 490�, 1.2 kHz

% Timing - TR = 32 ms
Model_qmtSPGR.Prot.TimingTable.Mat(1) = 0.0120;
Model_qmtSPGR.Prot.TimingTable.Mat(2) = 0.0032;
Model_qmtSPGR.Prot.TimingTable.Mat(3) = 0.0018;
Model_qmtSPGR.Prot.TimingTable.Mat(4) = 0.0150;
Model_qmtSPGR.Prot.TimingTable.Mat(5) = 0.0320;

Model_qmtSPGR.options.Readpulsealpha = 6;

% Set simulation options
Opt.Method = 'Analytical equation';
Opt.ResetMz = false;
Opt.SNR = 1000;

% Input parameters
% MTon
x = struct;
x.F = 0.16;
x.kr = 30;
x.R1f = 1;
x.R1r = 1;
x.T2f = 0.03;
x.T2r = 1.3e-05;

% Timing parameters for vfa_t1.analytical_solution function
% PDw - MToff
PDw_Model = vfa_t1;
paramsPDw.EXC_FA = 6;
paramsPDw.TR = 32; % ms

% T1w
T1w_Model = vfa_t1; 
paramsT1w.EXC_FA = 20;
paramsT1w.TR = 18; % ms

% Timing parameters for MTSAT_exec function
PDParams(1) = paramsPDw.EXC_FA;
PDParams(2) = paramsPDw.TR;
T1Params(1) = paramsT1w.EXC_FA;
T1Params(2) = paramsT1w.TR;
MTParams(1) = 6;
MTParams(2) = 32;
B1Params(1) = 1;

% Varying R1f value
R1f = 1:-0.1:0.2;

%%%%%%% Effect of the MT pulse shape %%%%%%%
% MT pulse options
MTpulses = {'hard','gaussian', 'gausshan', 'sinc','sinchann','sincgauss','fermi'};

% Get signal using different MT pulses
for ii=1:length(MTpulses)
    for jj=1:length(R1f)
        % Hard pulse
        if strcmp(MTpulses{ii},'hard')
            Model_qmtSPGR.options.MT_Pulse_Shape = MTpulses{ii};
        end
        
        % Gaussian pulse and Gaussian pulse with Hanning window
        if (strcmp(MTpulses{ii},'gaussian') || strcmp(MTpulses{ii},'gausshann'))
            Model_qmtSPGR.options.MT_Pulse_Bandwidth = 200;
            Model_qmtSPGR.options.MT_Pulse_Shape = MTpulses{ii};
        end
        
        % Sinc pulse and Sinc pulse with Hanning window
        if (strcmp(MTpulses{ii},'sinc') || strcmp(MTpulses{ii},'sinchann'))
            Model_qmtSPGR.options.MT_Pulse_SincTBW = 4;
            Model_qmtSPGR.options.MT_Pulse_Shape = MTpulses{ii};
        end
        
        % Sincgauss pulse
        if strcmp(MTpulses{ii},'sincgauss')
            Model_qmtSPGR.options.MT_Pulse_SincTBW = 4;
            Model_qmtSPGR.options.MT_Pulse_Bandwidth = 200;
            Model_qmtSPGR.options.MT_Pulse_Shape = MTpulses{ii};
        end
        
        % Fermi pulse
        if strcmp(MTpulses{ii},'fermi')
            % MT pulse fermi transition Tmt/33.81
            Model_qmtSPGR.options.MT_Pulse_Fermitransitiona = Model_qmtSPGR.Prot.TimingTable.Mat(1)/33.81;
            %Model_qmtSPGR.options.MT_Pulse_Fermitransitiona = 0.35;
            Model_qmtSPGR.options.MT_Pulse_Shape = MTpulses{ii};
        end
        
        % Signal
        x.R1f = R1f(jj);
        Signal_qmtSPGR = equation(Model_qmtSPGR, x, Opt);
        % PDw - MToff
        paramsPDw.T1 = 1/x.R1f*1000; % ms
        PDw = vfa_t1.analytical_solution(paramsPDw);
        % T1w
        paramsT1w.T1 = 1/x.R1f*1000; % ms
        T1w = vfa_t1.analytical_solution(paramsT1w);
        % MTon
        MT = Signal_qmtSPGR*PDw;
        qMT(ii,jj) = MT;
        
        % MTR calculation
        MTR(ii,jj) = 100*(PDw - MT)/PDw;
        
        % MTsat calculation
        dataMTsat.PDw = PDw;
        dataMTsat.T1w = T1w;
        dataMTsat.MTw = MT;
        [MTsaturation,~] = MTSAT_exec(dataMTsat, MTParams, PDParams, T1Params, B1Params);
        MTsat(ii,jj) = MTsaturation;
    end
end