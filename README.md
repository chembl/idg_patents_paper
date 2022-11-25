# idg_patents_paper

patents_with_bioactivities.pl this script is used to flag patents as potentially containing tables with bioactivity data. For this each patent file is searched using the following keywords: IC50,XC50, EC50, AC50, Ki, Kd, pIC50, pXC50, pEC50, pAC50, -log(IC50), -log(XC50),-log(EC50), -log(AC50), concentration to inhibit, IC-50, XC-50, EC-50, AC-50,IC 50, XC 50, EC 50, AC 50

targets_title_abstract.pl this script is used to find targets from a list (in a separate file) in the title or abstract of each patent, mentioned in specific phrases related to bioactivity data.

targets_description_claims.pl this script is used to find targets from a list (in a separate file) in the description or claims of each patent, mentioned in specific phrases related to bioactivity data.

The phrases searched for in the 2 last scripts are:
·     X inhibitors
·     Inhibitors of X
·     X inhibitor
·     Modulators of X
·     Modulation of X
·     Targeting X
·     X modulators
·     Binding specifically to X
·     X mutants
·     Inhibit X
·     Antibodies recognis|zing X
·     Modulating the X
·     Selective X inhibitors
·     X antagonists
·     X agonist
·     X selective binding compounds
·     Activity of X
·     X antibodies
·     X activity 
·     Inhibitor of X
·     X binding
·     Antibodies directed against X
·     Treatment of X related
·     Antibody for X
·     Anti-X antibody
·     Human anti-X
·     Antibodies to X
·     High X affinity
·     Inhibiting X
·     Blocks|block X
·     Blocking X
·     Ligand|ligands for X
·     Compounds that interact with X
·     Modulating the function of X
·     X ligand|ligands
