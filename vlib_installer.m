function vlib_installer(varargin)
% VLIB_INSTALLER Install/uninstall Texas Instruments Vision Library.
%
% Usage:
% 1. vlib_installer -> interactively install TI vision library
%
% 2. vlib_installer(vlibZipFile, vlibInstallDir) -> automatically install
%    vlibZipFile to vlibInstallDir
%
% Example:
%    vlib_installer('C:\ti\vlib.zip', 'C:\Program Files\matlab\Work')
%
%
pkgName = 'simulink_vlib';
error(nargchk(0, 2, nargin, 'struct'));

% Confirm that installation file is found
if (nargin > 0)
    vlibZipFile = varargin{1};
else
    vlibZipFile = '';
end
if (nargin > 1)
    vlibInstallDir = varargin{2};
else
    vlibInstallDir = '';
end

% Check vlibZipFile
if ~exist(vlibZipFile, 'file')
    vlibZipFile = getZipFile([pkgName '.zip']);
end

% First check if the zip file is in the current directory:
if ~exist(vlibZipFile, 'file')
    s = ['Cannot locate archive "', pkgName, '.zip".\n'];
    s = [s 'This file is required for the installation process.\n'];
    s = [s 'Please check file name and location and re-run installation script.'];
    error('vlib_installer:vlibNotFound', s);
end

% Ask for VLIB installation directory
if ~exist(vlibInstallDir, 'dir')
    vlibInstallDir = getInstallDir();
end
if isempty(vlibInstallDir)
    error('vlib_installer:vlibInstallCancelled', 'VLIB installation canceled.');
end

% Install files
clear mex;
clear functions;
fprintf('### Extracting VLIB archive to %s. Please wait...\n', vlibInstallDir);
unzip(vlibZipFile, vlibInstallDir);


% Update VLIB paths
fprintf('### VLIB installed. Updating MATLAB search path.\n');

% Add VLIB paths to MATLAB search path
addpath(fullfile(vlibInstallDir, pkgName));
addpath(fullfile(vlibInstallDir, pkgName, 'auto_gen'));
savepath;

% Rehash
rehash toolboxreset;
rehash toolboxcache;

% Update makeInfo files
updateRtwMakeCfg(fullfile(vlibInstallDir, pkgName));
clear functions;

% Finish
disp('### VLIB installation complete.');


%--------------------------------------------------------------------------
function zipFile = getZipFile(zipFileName)

% Bring up the file browser
promptstr = sprintf('Browse for vlib.zip ZIP archive');
pathstr   = '';
fname     = '';
while (ischar(fname) && ~exist(fullfile(pathstr, fname), 'file'))
    [fname, pathstr] = uigetfile('*.zip', promptstr, zipFileName);
end
if (pathstr ~= 0)
    zipFile = fullfile(pathstr, fname);
else
    zipFile = '';
end

%--------------------------------------------------------------------------
function installDir = getInstallDir()

% Bring up the file browser
promptstr = 'Browse for VLIB installation directory';
startDir  = fullfile(matlabroot);
pathstr = uigetdir(startDir, promptstr);
if (pathstr ~= 0)
    installDir = pathstr;
else
    installDir = '';
end

%--------------------------------------------------------------------------
function updateRtwMakeCfg(vlibInstallDir)

fid = fopen(fullfile(vlibInstallDir, 'auto_gen', 'rtwmakecfg1.m'), 'r');
if (fid < 0)
    error('vlib_installer:fileOpenError', ...
        ['Cannot open %s for reading / writing. ', ...
        'An update is required to this file for code generation. ', ...
        'Manually update <vlibInstallDir> field in this file to ', ...
        'reflect the absolute path name of VLIB installation directory.']);
end
fileTxt = fread(fid, inf, '*char').';
fclose(fid);

% Replace <vlibInstallDir> token with full path to VLIB installation
% directory
fileTxt = strrep(fileTxt, '<vlibInstallDir>', vlibInstallDir);

% Write new file
fid = fopen(fullfile(vlibInstallDir, 'auto_gen', 'rtwmakecfg.m'), 'w');
if (fid < 0)
    error('vlib_installer:fileOpenError', ...
        ['Cannot open %s for writing. ', ...
        'An update is required to this file for code generation. ', ...
        'Manually update <vlibInstallDir> field in this file to ', ...
        'reflect the absolute path name of VLIB installation directory.']);
end
count = fwrite(fid, fileTxt);
fclose(fid);
if (count ~= length(fileTxt))
    error('vlib_installer:fileWriteError', ...
        ['Cannot write to file %s. ', ...
        'An update is required to this file for code generation. ', ...
        'Manually update <vlibInstallDir> field in this file to ', ...
        'reflect the absolute path name of VLIB installation directory.']);
end
%[EOF]
