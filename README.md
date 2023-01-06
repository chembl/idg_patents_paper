# Scripts

The following scripts were developed as part of the work described in “Illuminating the druggable genome through patent bioactivity data”.
The goal was to search patents for bioactivity data of small molecules against a list of understudied targets.
There should be 1 directory called downloaded_patents that contains:

-subdirectories called downloaded_patents_0001, downloaded_patents_0002, etc. Each of these subdirectories contains patents files. In this case there were 750 patent files per directory, this number can be changed in the variable npat_per_dir in the scripts.

-1 subdirectory called pat_lists, that contains files called pat_list_1, pat_list_2, etc. Each of these files contains a list of patent file names, one per line. In this case there are 750 lines with patent file names. This number can be modified in the variable npat_per_file in the scripts.

This directories/files structure was the most adequate for the system used but can be changed as needed.
To run the scripts, the command should be:
`perl patents_with_bioactivities.pl <max_index>`
`perl targets_title_abstract.pl <max_index>`
`perl targets_descriptions_claims.pl <max_index>`
where max_index is the number of directories (the ones called downloaded_patents_0001, downloaded_patents_0002 etc.). In this case there were 650 directories so the command should be:
perl patents_with_bioactivities.pl 650

## patents_with_bioactivities.pl
This script is used to flag patents as potentially containing tables with bioactivity data. For this each patent file is searched using the following keywords: IC50,XC50, EC50, AC50, Ki, Kd, pIC50, pXC50, pEC50, pAC50, -log(IC50), -log(XC50),-log(EC50), -log(AC50), concentration to inhibit, IC-50, XC-50, EC-50, AC-50,IC 50, XC 50, EC 50, AC 50

## targets_title_abstract.pl
This script is used to find targets from a list (in a separate file) in the title or abstract of each patent, mentioned in specific phrases related to bioactivity data.

## targets_description_claims.pl
This script is used to find targets from a list (in a separate file) in the description or claims of each patent, mentioned in specific phrases related to bioactivity data.

### The phrases searched for in the 2 last scripts are:

- X inhibitors
- Inhibitors of X
- X inhibitor
- Modulators of X
- Modulation of X
- Targeting X
- X modulators
- Binding specifically to X
- X mutants
- Inhibit X
- Antibodies recognis|zing X
- Modulating the X
- Selective X inhibitors
- X antagonists
- X agonist
- X selective binding compounds
- Activity of X
- X antibodies
- X activity 
- Inhibitor of X
- X binding
- Antibodies directed against X
- Treatment of X related
- Antibody for X
- Anti-X antibody
- Human anti-X
- Antibodies to X
- High X affinity
- Inhibiting X
- Blocks|block X
- Blocking X
- Ligand|ligands for X
- Compounds that interact with X
- Modulating the function of X
- X ligand|ligands
