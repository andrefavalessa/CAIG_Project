function out=figrepro_outputDirectory(projectRoot,label,out)
%FIGREPRO_OUTPUTDIRECTORY New empty directory; never overwrite prior results.
if nargin<3 || isempty(out)
    parent=fullfile(projectRoot,'outputs','runs');
    if ~isfolder(parent), mkdir(parent); end
    [~,unique]=fileparts(tempname(parent));
    out=fullfile(parent,[label '_' unique]);
end
if isfolder(out)
    entries=dir(out);
    assert(all(ismember({entries.name},{'.','..'})), ...
        'figrepro:OutputExists','Output directory must be empty: %s',out);
else
    [ok,msg]=mkdir(out); assert(ok,'figrepro:OutputDirectory','%s',msg);
end
end
