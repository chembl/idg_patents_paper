#!/usr/bin/perl
use 5.010;
use XML::LibXML;;
use POSIX;
$ENV{'NLS_LANG'} = 'AMERICAN_AMERICA.AL32UTF8';

my $file_index = $ARGV[0];

open(TSYN, "<all_tdark_tbio_2022_list"); #file with the list of targets to search for

$| = 1;

open(RESULT, ">descr_$file_index");

my %syns;
while (my $line =<TSYN>) {
  chomp($line);
  $syns{lc($line)} = 1;
}

my $npat_per_file = 750;
my $npat_per_dir = 750;

my $dir_index = ceil($file_index*$npat_per_file/$npat_per_dir);
my $dir = "downloaded_patents_" . sprintf("%04d", $dir_index);

opendir(LASTUPD, "$dir"); #directory with the patents
open(PAT_LIST, "<pat_lists/pat_list_$file_index");

my %pat_list;
while (my $line = <PAT_LIST>) {
  chomp($line);
  my $id = $line;
  $pat_list{$id}=1;
}

my @description_matches;
my @claims_matches;
my $found = 0;
my $description_text;
my $claims_text;
my %description_matches;
my %claims_matches;
my %pos;
my @exact;
my @free;
my $useful_text;
my $useful_description;
my @description_text;
my %phrases;
my @descriptions;
my @claims;

while (my $filename =  readdir LASTUPD) {
  if ($filename !~/\.xml/) {next;}
  if (!exists $pat_list{$filename}) {next;}

  my $dom = XML::LibXML->load_xml(location => "$dir/$filename");

  foreach my $npat ($dom->findnodes('/patent-document/@ucid')) {
    $found = 0;
    @description_matches = ();
    @claims_matches = ();
    undef %description_matches;
    undef %claims_matches;
    my $match_description;
    my $match_claim;
  
    foreach my $description ($npat->findnodes('/patent-document/description[@lang="EN"]/*[not(self::citation-list) and not(self::invention-title)]')) {
      foreach my $n (keys %descriptions) {
        @{ $descriptions{$n}} =();
      }
  
      undef %phrases;
      $description_text = $description->to_literal();
  
      while ($description_text =~/inhibitors/ig) {
        $phrases{1}=1;
        my $start = $-[0]-123; if ($start <0) {$start =0;}
        push @{ $descriptions{1}}, substr($description_text, $start, $+[0]-$start);
      }
      while ($description_text =~/inhibitors of/ig) {
        $phrases{3}=1;
        my $end = $+[0]+122;
        push @{ $descriptions{3}}, substr($description_text, $-[0], 135);
      }
      while ($description_text =~/inhibitor\b/ig) {
        $phrases{4}=1;
        my $start = $-[0]-123; if ($start<0) {$start =0;}
        push @{ $descriptions{4}}, substr($description_text, $start, $+[0]-$start);
      }
      while ($description_text =~/modulators of/ig) {
        $phrases{5}=1;
        my $end = $+[0]+122;
        push @{ $descriptions{5}}, substr($description_text, $-[0], 135);
      }
      while ($description_text =~/modulation of/ig) {
        $phrases{6}=1;
        my $end = $+[0]+122;
        push @{ $descriptions{6}}, substr($description_text, $-[0], 135);
      }
      while ($description_text =~/targeting/ig) {
        $phrases{7}=1;
        my $end = $+[0]+122;
        push @{ $descriptions{7}}, substr($description_text, $-[0], 131);
      }
      while ($description_text =~/modulators/ig) {
        $phrases{8}=1;
        my $start = $-[0]-123; if ($start<0) {$start =0;}
        push @{ $descriptions{8}}, substr($description_text, $start, $+[0]-$start);
      }
      while ($description_text =~/binding specifically to/ig) {
        $phrases{9}=1;
        my $end = $+[0]+122;
        push @{ $descriptions{9}}, substr($description_text, $-[0], 146);
      }
      while ($description_text =~/mutants/ig) {
        $phrases{12}=1;
        my $start = $-[0]-123; if ($start<0) {$start =0;}
        push @{ $descriptions{12}}, substr($description_text, $start, $+[0]-$start);
      }
      while ($description_text =~/\binhibit\b/ig) {
        $phrases{13}=1;
        my $end = $+[0]+122;
        push @{ $descriptions{13}}, substr($description_text, $-[0], 130);
      }
      while ($description_text =~/antibodies recogni(s|z)ing/ig) {
        $phrases{14}=1;
        my $end = $+[0]+122;
        push @{ $descriptions{14}}, substr($description_text, $-[0], 145);
      }
      while ($description_text =~/modulating the/ig) {
        $phrases{17}=1;
        my $end = $+[0]+122;
        push @{ $descriptions{17}}, substr($description_text, $-[0], 137);
      }
      while ($description_text =~/selective .+? inhibitors/ig) {
        $phrases{18}=1;
        my $start = $-[0];
        my $end = $+[0];
        push @{ $descriptions{18}}, substr($description_text, $start, ($end-$start));
      }
      while ($description_text =~/antagonist/ig) {
        $phrases{19}=1;
        my $start = $-[0]-123; if ($start<0) {$start =0;}
        push @{ $descriptions{19}}, substr($description_text, $start, $+[0]-$start);
      }
      while ($description_text =~/\bagonist/ig) {
      $phrases{20}=1;
      my $start = $-[0]-123; if ($start<0) {$start =0;}
      push @{ $descriptions{20}}, substr($description_text, $start, $+[0]-$start);
      }
      while ($description_text =~/selective binding compounds/ig) {
        $phrases{21}=1;
        my $start = $-[0]-123; if ($start<0) {$start =0;}
        push @{ $descriptions{21}}, substr($description_text, $start, $+[0]-$start);
      }
      while ($description_text =~/activity of/ig) {
        $phrases{24}=1;
        my $end = $+[0]+122;
        push @{ $descriptions{24}}, substr($description_text, $-[0], 134);
      }
      while ($description_text =~/antibodies/ig) {
        $phrases{25}=1;
        my $start = $-[0]-123; if ($start<0) {$start =0;}
        push @{ $descriptions{25}}, substr($description_text, $start, $+[0]-$start);
      }
      while ($description_text =~/\bactivity/ig) {
        $phrases{26}=1;
        my $start = $-[0]-123; if ($start<0) {$start =0;}
        push @{ $descriptions{26}}, substr($description_text, $start, $+[0]-$start);
      }
      while ($description_text =~/inhibitor of/ig) {
        $phrases{27}=1;
        my $end = $+[0]+122;
        push @{ $descriptions{27}}, substr($description_text, $-[0], 134);
      }
      while ($description_text =~/binding/ig) {
        $phrases{29}=1;
        my $start = $-[0]-123; if ($start<0) {$start =0;}
        push @{ $descriptions{29}}, substr($description_text, $start, $+[0]-$start);
      }
      while ($description_text =~/antibodies directed against/ig) {
        $phrases{30}=1;
        my $end = $+[0]+122;
        push @{ $descriptions{30}}, substr($description_text, $-[0], 150);
      }
      while ($description_text =~/treatment of .+? related/ig) {
        $phrases{31}=1;
        my $start = $-[0];
        my $end = $+[0];
        push @{ $descriptions{31}}, substr($description_text, $start, ($end-$start));
      }
      while ($description_text =~/antibody for/ig) {
        $phrases{32}=1;
        my $end = $+[0]+122;
        push @{ $descriptions{32}}, substr($description_text, $-[0], 137);
      }
      while ($description_text =~/anti-.+? antibody/ig) {
        $phrases{33}=1;
        my $start = $-[0];
        my $end = $+[0];
        push @{ $descriptions{33}}, substr($description_text, $start, ($end-$start));
      }
      while ($description_text =~/human anti-.+?(?!\s*antibody)/ig) {
        $phrases{34}=1;
        my $end = $+[0]+122;
        push @{ $descriptions{34}}, substr($description_text, $-[0], 133);
      }
      while ($description_text =~/antibodies to/ig) {
        $phrases{35}=1;
        my $end = $+[0]+122;
        push @{ $descriptions{35}}, substr($description_text, $-[0], 136);
      }
      while ($description_text =~/high .+? affinity/ig) {
        $phrases{36}=1;
        my $start = $-[0];
        my $end = $+[0];
        push @{ $descriptions{36}}, substr($description_text, $start, ($end-$start));
      }
      while ($description_text =~/inhibiting/ig) {
        $phrases{39}=1;
        my $end = $+[0]+122;
        push @{ $descriptions{39}}, substr($description_text, $-[0], 137);
      }
      while ($description_text =~/\bblock/ig) {
        $phrases{40}=1;
        my $end = $+[0]+122;
        push @{ $descriptions{40}}, substr($description_text, $-[0], 137);
      }
      while ($description_text =~/blocking/ig) {
        $phrases{41}=1;
        my $end = $+[0]+122;
        push @{ $descriptions{41}}, substr($description_text, $-[0], 137);
      }
      while ($description_text =~/ligand for/ig) {
        $phrases{42}=1;
        my $end = $+[0]+122;
        push @{ $descriptions{42}}, substr($description_text, $-[0], 137);
      }
      while ($description_text =~/ligands for/ig) {
        $phrases{42}=1;
        my $end = $+[0]+122;
        push @{ $descriptions{42}}, substr($description_text, $-[0], 137);
      }
      while ($description_text =~/compounds that interact with/ig) {
        $phrases{43}=1;
        my $end = $+[0]+122;
        push @{ $descriptions{43}}, substr($description_text, $-[0], 137);
      }
      while ($description_text =~/modulating the function of/ig) {
        $phrases{44}=1;
        my $end = $+[0]+122;
        push @{ $descriptions{44}}, substr($description_text, $-[0], 137);
      }
      while ($description_text =~/ligand/ig) {
        $phrases{45}=1;
        my $start = $-[0]-123; if ($start<0) {$start =0;}
        push @{ $descriptions{45}}, substr($description_text, $start, $+[0]-$start);
      }
  
      if (keys %phrases == 0) {next;}
      foreach my $syn (sort { length($b) <=> length($a) } keys %syns) {
        $match_description = 0;
        while ($description_text =~m/\b\Q$syn\E\b/ig) {
          my $start = $-[0];
          my $end = $+[0];
          if (scalar(keys %description_matches) == 0) {
            $description_matches{$syn}=1;
            $pos{lc($syn)} =  {start => $-[0], end => $+[0]};
          } else {
            OUTER: foreach my $a (keys %description_matches) {
              if (($pos{lc($a)}->{end} >= $end and $pos{lc($a)}->{start} < $start) or ($pos{lc($a)}->{start} <= $start and $pos{lc($a)}->{end} > $end)) {
                $match_description = 1;
                last;
              }
              if ($match_description == 0) {
                $description_matches{$syn}=1;
                $pos{lc($syn)} = {start => $-[0], end => $+[0]};
              }
            }
          }
        }
      } 
      if (keys %description_matches ==0) {next;}
      if ($phrases{1}==1) {
        foreach my $description_text2 (@{ $descriptions{1}}) {
          foreach my $syn (sort { length($b) <=> length($a) } keys %description_matches) {
            if ($description_text2 =~/\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*inhibitors$/ig) {
              my $append;
              if ($1 ne '') {
                if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                  $append = 'receptor';
                } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                  $append = 'kinase';
                }
                  push @description_matches, "EXACT 1: " . $syn . " $append"; last;
              } else {
                push @description_matches, "EXACT 1: " .$syn; last;
              }
            }
          }
        }
      }
      if ($phrases{3}==1) {
        foreach my $description_text2 (@{ $descriptions{3}}) {
          foreach my $syn (sort { length($b) <=> length($a) } keys %description_matches) {
            if ($description_text2 =~/^inhibitors of (?:soluble|the human|human)?\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig) {
              my $append;
              if ($1 ne '') {
                if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                  $append = 'receptor';
                } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                  $append = 'kinase';
                }
                push @description_matches, "EXACT 3: " .$syn. " $append"; last;
              } else {
                push @description_matches, "EXACT 3: " .$syn; last;
              }
            }
          }
        }
      }
      if ($phrases{4}==1) {
        foreach my $description_text2 (@{ $descriptions{4}}) {
          foreach my $syn (sort { length($b) <=> length($a) } keys %description_matches) {
            if ($description_text2 =~/\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*inhibitor\b$/ig) {
              my $append;
              if ($1 ne '') {
                if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                  $append = 'receptor';
                } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                  $append = 'kinase';
                }
                push @description_matches, "EXACT 4: " .$syn. " $append"; last;
              } else {
                push @description_matches, "EXACT 4: " .$syn; last;
              }
            }
          }
        }
      }
      if ($phrases{5}==1) {
        foreach my $description_text2 (@{ $descriptions{5}}) {
          foreach my $syn (sort { length($b) <=> length($a) } keys %description_matches) {
            if ($description_text2 =~/^modulators of\s*(?:the)?\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig) {
              my $append;
              if ($1 ne '') {
                if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                  $append = 'receptor';
                } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                  $append = 'kinase';
                }
                push @description_matches, "EXACT 5: " .$syn. " $append"; last;
              } else {
                push @description_matches, "EXACT 5: " .$syn; last;
              }
            }
          }
        }
      }
      if ($phrases{6}==1) {
        foreach my $description_text2 (@{ $descriptions{6}}) {
          foreach my $syn (sort { length($b) <=> length($a) } keys %description_matches) {
            if ($description_text2 =~/^modulation of\s*(?:the)?\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig) {
              my $append;
              if ($1 ne '') {
                if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                  $append = 'receptor';
                } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                  $append = 'kinase';
                }
                push @description_matches, "EXACT 6: " .$syn. " $append"; last;
              } else {
                push @description_matches, "EXACT 6: " .$syn; last;
              }
            }
          }
        }
      }
      if ($phrases{7}==1) {
        foreach my $description_text2 (@{ $descriptions{7}}) {
          foreach my $syn (sort { length($b) <=> length($a) } keys %description_matches) {
            if ($description_text2 =~/^targeting\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig) {
              my $append;
              if ($1 ne '') {
                if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                  $append = 'receptor';
                } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                  $append = 'kinase';
                }
                push @description_matches, "EXACT 7: " .$syn. " $append"; last;
              } else {
                push @description_matches, "EXACT 7: " .$syn; last;
              }
            }
          }
        }
      }
      if ($phrases{8}==1) {
        foreach my $description_text2 (@{ $descriptions{8}}) {
          foreach my $syn (sort { length($b) <=> length($a) } keys %description_matches) {
            if ($description_text2 =~/\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*modulators$/ig) {
              my $append;
              if ($1 ne '') {
                if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                  $append = 'receptor';
                } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                  $append = 'kinase';
                }
                push @description_matches, "EXACT 8: " .$syn. " $append"; last;
              } else {
                push @description_matches, "EXACT 8: " .$syn; last;
              }
            }
          }
        }
      }
      if ($phrases{9}==1) {
        foreach my $description_text2 (@{ $descriptions{9}}) {
          foreach my $syn (sort { length($b) <=> length($a) } keys %description_matches) {
            if ($description_text2 =~/^binding specifically to\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig) {
              my $append;
              if ($1 ne '') {
                if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                  $append = 'receptor';
                } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                  $append = 'kinase';
                }
                push @description_matches, "EXACT 9: " .$syn. " $append"; last;
              } else {
                push @description_matches, "EXACT 9: " .$syn; last;
              }
            }
          }
        }
      } 
      if ($phrases{12}==1) {
        foreach my $description_text2 (@{ $descriptions{12}}) {
          foreach my $syn (sort { length($b) <=> length($a) } keys %description_matches) {
            if ($description_text2 =~/\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*mutants$/ig) {
              my $append;
              if ($1 ne '') {
                if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                  $append = 'receptor';
                } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                  $append = 'kinase';
                }
                push @description_matches, "EXACT 12: " .$syn. " $append"; last;
              } else {
                push @description_matches, "EXACT 12: " .$syn; last;
              }
            }
          }
        }
      }
      if ($phrases{13}==1) {
        foreach my $description_text2 (@{ $descriptions{13}}) {
          foreach my $syn (sort { length($b) <=> length($a) } keys %description_matches) {
            if ($description_text2 =~/^inhibit\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig) {
              my $append;
              if ($1 ne '') {
                if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                  $append = 'receptor';
                } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                  $append = 'kinase';
                }
                push @description_matches, "EXACT 13: " .$syn. " $append"; last;
              } else {
                push @description_matches, "EXACT 13: " .$syn; last;
              }
            }
          }
        }
      }
      if ($phrases{14}==1) {
        foreach my $description_text2 (@{ $descriptions{14}}) {
          foreach my $syn (sort { length($b) <=> length($a) } keys %description_matches) {
            if ($description_text2 =~/(?:^monoclonal antibodies|^antibodies)\s*recogni(?:z|s)ing\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig) {
              my $append;
              if ($1 ne '') {
                if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                  $append = 'receptor';
                } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                  $append = 'kinase';
                }
                push @description_matches, "EXACT 14: " .$syn. " $append"; last;
              } else {
                push @description_matches, "EXACT 14: " .$syn; last;
              }
            }
          }
        }
      }
      if ($phrases{17}==1) {
        foreach my $description_text2 (@{ $descriptions{17}}) {
          foreach my $syn (sort { length($b) <=> length($a) } keys %description_matches) {
            if ($description_text2 =~/^modulating the\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig) {
              my $append;
              if ($1 ne '') {
                if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                  $append = 'receptor';
                } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                  $append = 'kinase';
                }
                push @description_matches, "EXACT 17: " .$syn. " $append"; last;
              } else {
                push @description_matches, "EXACT 17: " .$syn; last;
              }
            }
          }
        }
      }
      if ($phrases{18}==1) { 
        foreach my $description_text2 (@{ $descriptions{18}}) {
          foreach my $syn (sort { length($b) <=> length($a) } keys %description_matches) {
            if ($description_text2 =~/^selective\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*inhibitors/ig) {         
              my $append;
              if ($1 ne '') {
                if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                  $append = 'receptor';
                } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                  $append = 'kinase';
                }
                push @description_matches, "EXACT 18: " .$syn. " $append"; last;
              } else {
                push @description_matches, "EXACT 18: " .$syn; last;
              }
            }
          }
        }
      }
      if ($phrases{19}==1) {
        foreach my $description_text2 (@{ $descriptions{19}}) {
          foreach my $syn (sort { length($b) <=> length($a) } keys %description_matches) {
            if ($description_text2 =~/\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*(?:non competitive|non-competitive|competitive)?\s*(?:antagonists|antagonist\b)$/ig) {
              my $append;
              if ($1 ne '') {
                if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                  $append = 'receptor';
                } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                  $append = 'kinase';
                }
                push @description_matches, "EXACT 19: " .$syn . " $append"; last;
              } else {
                push @description_matches, "EXACT 19: " .$syn; last;
              }
            }
          }
        }
      }
      if ($phrases{20}==1) {
        foreach my $description_text2 (@{ $descriptions{20}}) {
          foreach my $syn (sort { length($b) <=> length($a) } keys %description_matches) {
            if ($description_text2 =~/\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*(?:agonist|agonists|partial agonist|partial agonists|inverse agonist|inverse agonists)$/ig) {
              my $append;
              if ($1 ne '') {
                if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                  $append = 'receptor';
                } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                  $append = 'kinase';
                }
                push @description_matches, "EXACT 20: " .$syn. " $append"; last;
              } else {
                push @description_matches, "EXACT 20: " .$syn; last;
              }
            }
          }
        }
      }
      if ($phrases{21}==1) {
        foreach my $description_text2 (@{ $descriptions{21}}) {
          foreach my $syn (sort { length($b) <=> length($a) } keys %description_matches) {
            if ($description_text2 =~/\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*selective binding compounds$/ig) {
              my $append;
              if ($1 ne '') {
                if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                  $append = 'receptor';
                } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                  $append = 'kinase';
                }
                push @description_matches, "EXACT 21: " .$syn . " $append"; last;
              } else {
                push @description_matches, "EXACT 21: " .$syn; last;
              }
            }
          }
        }
      }
      if ($phrases{24}==1) {
        foreach my $description_text2 (@{ $descriptions{24}}) {
          foreach my $syn (sort { length($b) <=> length($a) } keys %description_matches) {
            if ($description_text2 =~/^activity of\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig) {
            my $append;
              if ($1 ne '') {
                if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                  $append = 'receptor';
                } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                  $append = 'kinase';
                }
                push @description_matches, "EXACT 24: " .$syn . " $append"; last;
              } else {
                push @description_matches, "EXACT 24: " .$syn; last;
              }
            }
          }
        }
      }
      if ($phrases{25}==1) {
        foreach my $description_text2 (@{ $descriptions{25}}) {
          foreach my $syn (sort { length($b) <=> length($a) } keys %description_matches) {
            if ($description_text2 =~/(?:anti-)?\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*(?:specific)?\s*(?:monoclonal antibodies|antibodies)/ig) {
              my $append;
              if ($1 ne '') {
                if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                  $append = 'receptor';
                } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                  $append = 'kinase';
                }
                push @description_matches, "EXACT 25: " .$syn . " $append"; last;
              } else {
                push @description_matches, "EXACT 25: " .$syn; last;
              }
            }
          }
        }
      }
      if ($phrases{26}==1) {
        foreach my $description_text2 (@{ $descriptions{26}}) {
          foreach my $syn (sort { length($b) <=> length($a) } keys %description_matches) {
            if ($description_text2 =~/\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*(?:inhibitory|inhibiting|antagonistic)?\s*\bactivity$/ig) {
              my $append;
              if ($1 ne '') {
                if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                  $append = 'receptor';
                } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                  $append = 'kinase';
                }
                push @description_matches, "EXACT 26: " .$syn . " $append"; last;
              } else {
                push @description_matches, "EXACT 26: " .$syn; last;
              }
            } 
          }
        }
      }
      if ($phrases{27}==1) {
        foreach my $description_text2 (@{ $descriptions{27}}) {
          foreach my $syn (sort { length($b) <=> length($a) } keys %description_matches) {
            if ($description_text2 =~/^inhibitor of\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig) {
              my $append;
              if ($1 ne '') {
                if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                  $append = 'receptor';
                } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                  $append = 'kinase';
                }
                push @description_matches, "EXACT 27: " .$syn . " $append"; last;
              } else {
                push @description_matches, "EXACT 27: " .$syn; last;
              }
            }
          }
        }
      }
      if ($phrases{29}==1) {
        foreach my $description_text2 (@{ $descriptions{29}}) {
          foreach my $syn (sort { length($b) <=> length($a) } keys %description_matches) {
            if ($description_text2 =~/\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*binding$/ig) {
              my $append;
              if ($1 ne '') {
                if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                  $append = 'receptor';
                } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                  $append = 'kinase';
                }
                push @description_matches, "EXACT 29: " .$syn. " $append"; last;
              } else {
                push @description_matches, "EXACT 29: " .$syn; last;
              }
            }
          }
        }
      }
      if ($phrases{30}==1) {
        foreach my $description_text2 (@{ $descriptions{30}}) {
          foreach my $syn (sort { length($b) <=> length($a) } keys %description_matches) {
            if ($description_text2 =~/(?:monoclonal antibodies|antibodies)\s*directed against\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig) {
              my $append;
              if ($1 ne '') {
                if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                  $append = 'receptor';
                } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                  $append = 'kinase';
                }
                push @description_matches, "EXACT 30: " .$syn. " $append"; last;
              } else {
                push @description_matches, "EXACT 30: " .$syn; last;
              }
            }
          }
        }
      }
      if ($phrases{31}==1) {
        foreach my $description_text2 (@{ $descriptions{31}}) {
          foreach my $syn (sort { length($b) <=> length($a) } keys %description_matches) {
            if ($description_text2 =~/treatment of\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*related/ig) {
              my $append;
              if ($1 ne '') {
                if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                  $append = 'receptor';
                } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                  $append = 'kinase';
                }
                push @description_matches, "EXACT 31: " .$syn. " $append"; last;
              } else {
                push @description_matches, "EXACT 31: " .$syn; last;
              }
            }
          }
        }
      }
      if ($phrases{32}==1) {
        foreach my $description_text2 (@{ $descriptions{32}}) {
          foreach my $syn (sort { length($b) <=> length($a) } keys %description_matches) {
            if ($description_text2 =~/(?:monoclonal antibody|antibody)\s*for\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig)  {
              my $append;
              if ($1 ne '') {
                if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                  $append = 'receptor';
                } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                  $append = 'kinase';
                }
                push @description_matches, "EXACT 32: " .$syn . " $append";last;
              } else {
                push @description_matches, "EXACT 32: " .$syn; last;
              }
            }
          }
        }
      }
      if ($phrases{33}==1) {
        foreach my $description_text2 (@{ $descriptions{33}}) {
          foreach my $syn (sort { length($b) <=> length($a) } keys %description_matches) {
            if ($description_text2 =~/anti-\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*(?:monoclonal antibody|antibody)/ig) {
              my $append;
              if ($1 ne '') {
                if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                  $append = 'receptor';
                } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                  $append = 'kinase';
                }
                push @description_matches, "EXACT 33: " .$syn . " $append";last;
              } else {
                push @description_matches, "EXACT 33: " .$syn; last;
              }
            }
          }
        }
      }
      if ($phrases{34}==1) {
        foreach my $description_text2 (@{ $descriptions{34}}) {
          foreach my $syn (sort { length($b) <=> length($a) } keys %description_matches) {
            if ($description_text2 =~/^human anti-\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig) {
              my $append;
              if ($1 ne '') {
                if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                  $append = 'receptor';
                } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                  $append = 'kinase';
                }
                push @description_matches, "EXACT 34: " .$syn . " $append";last;
              } else {
                push @description_matches, "EXACT 34: " .$syn; last;
              }
            }
          }
        }
      }
      if ($phrases{35}==1) {
        foreach my $description_text2 (@{ $descriptions{35}}) {
          foreach my $syn (sort { length($b) <=> length($a) } keys %description_matches) {
            if ($description_text2 =~/(?:monoclonal antibodies|antibodies)\s*to\s*(?:human)?\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig) {
              my $append;
              if ($1 ne '') {
                if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                  $append = 'receptor';
                } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                  $append = 'kinase';
                }
                push @description_matches, "EXACT 35: " .$syn . " $append"; last;
              } else {
                push @description_matches, "EXACT 35: " .$syn; last;
              }
            }
          }
        }
      }
      if ($phrases{36}==1) {
        foreach my $description_text2 (@{ $descriptions{36}}) {
          foreach my $syn (sort { length($b) <=> length($a) } keys %description_matches) {
            if ($description_text2 =~/high\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*affinity/ig) {
              my $append;
              if ($1 ne '') {
                if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                  $append = 'receptor';
                } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                  $append = 'kinase';
                }
                push @description_matches, "EXACT 36: " .$syn . " $append"; last;
              } else {
                push @description_matches, "EXACT 36: " .$syn; last;
              }
            }
          }
        }
      }
      if ($phrases{39}==1) {
        foreach my $description_text2 (@{ $descriptions{39}}) {
          foreach my $syn (sort { length($b) <=> length($a) } keys %description_matches) {
            if ($description_text2 =~/^inhibiting\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig)  {
              my $append;
              if ($1 ne '') {
                if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                  $append = 'receptor';
                } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                  $append = 'kinase';
                }
                push @description_matches, "EXACT 39: " .$syn . " $append"; last;
              } else {
                push @description_matches, "EXACT 39: " .$syn; last;
              }
            }
          }
        }
      }
      if ($phrases{40}==1) {
        foreach my $description_text2 (@{ $descriptions{40}}) {
          foreach my $syn (sort { length($b) <=> length($a) } keys %description_matches) {
            if ($description_text2 =~/^(?:blocks\b|block\b)\s*(?:the)?\s*\b\Q$syn\E\b(receptor|kinase|receptors|kinases)?/ig) {
              my $append;
              if ($1 ne '') {
                if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                  $append = 'receptor';
                } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                  $append = 'kinase';
                }
                push @description_matches, "EXACT 40: " .$syn . " $append"; last;
              } else {
                push @description_matches, "EXACT 40: " .$syn; last;
              }
            }
          }
        }
      }
      if ($phrases{41}==1) {
        foreach my $description_text2 (@{ $descriptions{41}}) {
          foreach my $syn (sort { length($b) <=> length($a) } keys %description_matches) {
            if ($description_text2 =~/^blocking\b\s*(?:the\b|a\b|an\b)?\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig) {
              my $append;
              if ($1 ne '') {
                if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                  $append = 'receptor';
                } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                  $append = 'kinase';
                }
                push @description_matches, "EXACT 41: " .$syn . " $append"; last;
              } else {
                push @description_matches, "EXACT 41: " .$syn; last;
              }
            }
          }
        }
      }
      if ($phrases{42}==1) {
        foreach my $description_text2 (@{ $descriptions{42}}) {
          foreach my $syn (sort { length($b) <=> length($a) } keys %description_matches) {
            if ($description_text2 =~/^(?:ligand|ligands)\s*(?:for the\b|for\b)\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig) {
              my $append;
              if ($1 ne '') {
                if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                  $append = 'receptor';
                } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                  $append = 'kinase';
                }
                push @description_matches, "EXACT 42: " .$syn . " $append"; last;
              } else {
                push @description_matches, "EXACT 42: " .$syn; last;
              }
            }
          }
        }
      }
      if ($phrases{43}==1) {
        foreach my $description_text2 (@{ $descriptions{43}}) {
          foreach my $syn (sort { length($b) <=> length($a) } keys %description_matches) {
            if ($description_text2 =~/^compounds that interact with (?:the\b)?\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig) {
              my $append;
              if ($1 ne '') {
                if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                  $append = 'receptor';
                } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                  $append = 'kinase';
                }
                push @description_matches, "EXACT 43: " .$syn . " $append"; last;
              } else {
                push @description_matches, "EXACT 43: " .$syn; last;
              }
            }
          }
        }
      }
      if ($phrases{44}==1) {
        foreach my $description_text2 (@{ $descriptions{44}}) {
          foreach my $syn (sort { length($b) <=> length($a) } keys %description_matches) {
            if ($description_text2 =~/^modulating the function of\s*(?:a\b|an\b|the\b)?\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig) {
              my $append;
              if ($1 ne '') {
                if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                  $append = 'receptor';
                } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                  $append = 'kinase';
                }
                push @description_matches, "EXACT 44: " .$syn . " $append";  last;
              } else {
                push @description_matches, "EXACT 44: " .$syn; last;
              }
            }
          }
        }
      }
      if ($phrases{45}==1) {
        foreach my $description_text2 (@{ $descriptions{45}}) {
          foreach my $syn (sort { length($b) <=> length($a) } keys %description_matches) {
            if ($description_text2 =~/\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*(?:ligand\b|ligands)\b$/ig) {
              my $append;
              if ($1 ne '') {
                if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                  $append = 'receptor';
                } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                  $append = 'kinase';
                }
                push @description_matches, "EXACT 45: " .$syn . " $append"; last;
              } else {
                push @description_matches, "EXACT 45: " .$syn; last;
              }
            }
          }
        }
      }
    }
#-----claims

    foreach my $claims ($npat->findnodes('/patent-document/claims[@lang="EN"]')) {
      foreach my $n (keys %claims) {
        @{ $claims{$n}} =();
      }
      undef %phrases;
  
      $claims_text = $claims->to_literal();
  
      while ($claims_text =~/inhibitors/ig) {
        $phrases{1}=1;
        my $start = $-[0]-123; if ($start <0) {$start =0;}
        push @{ $claims{1}}, substr($claims_text, $start, $+[0]-$start);
      }
      while ($claims_text =~/inhibitors of/ig) {
        $phrases{3}=1;
        my $end = $+[0]+122;
        push @{ $claims{3}}, substr($claims_text, $-[0], 135);
      }
      while ($claims_text =~/inhibitor\b/ig) {
        $phrases{4}=1;
        my $start = $-[0]-123; if ($start<0) {$start =0;}
        push @{ $claims{4}}, substr($claims_text, $start, $+[0]-$start);
      }
      while ($claims_text =~/modulators of/ig) {
        $phrases{5}=1;
        my $end = $+[0]+122;
        push @{ $claims{5}}, substr($claims_text, $-[0], 135);
      }
      while ($claims_text =~/modulation of/ig) {
        $phrases{6}=1;
        my $end = $+[0]+122;
        push @{ $claims{6}}, substr($claims_text, $-[0], 135);
      }
      while ($claims_text =~/targeting/ig) {
        $phrases{7}=1;
        my $end = $+[0]+122;
        push @{ $claims{7}}, substr($claims_text, $-[0], 131);
      }
      while ($claims_text =~/modulators/ig) {
        $phrases{8}=1;
        my $start = $-[0]-123; if ($start<0) {$start =0;}
        push @{ $claims{8}}, substr($claims_text, $start, $+[0]-$start);
      }
      while ($claims_text =~/binding specifically to/ig) {
        $phrases{9}=1;
        my $end = $+[0]+122;
        push @{ $claims{9}}, substr($claims_text, $-[0], 146);
      }
      while ($claims_text =~/mutants/ig) {
        $phrases{12}=1;
        my $start = $-[0]-123; if ($start<0) {$start =0;}
        push @{ $claims{12}}, substr($claims_text, $start, $+[0]-$start);
      }
      while ($claims_text =~/\binhibit\b/ig) {
        $phrases{13}=1;
        my $end = $+[0]+122;
        push @{ $claims{13}}, substr($claims_text, $-[0], 130);
      }
      while ($claims_text =~/antibodies recogni(s|z)ing/ig) {
        $phrases{14}=1;
        my $end = $+[0]+122;
        push @{ $claims{14}}, substr($claims_text, $-[0], 145);
      }
      while ($claims_text =~/modulating the/ig) {
        $phrases{17}=1;
        my $end = $+[0]+122;
        push @{ $claims{17}}, substr($claims_text, $-[0], 137);
      }
      while ($claims_text =~/selective .+? inhibitors/ig) {
        $phrases{18}=1;
        my $start = $-[0];
        my $end = $+[0];
        push @{ $claims{18}}, substr($claims_text, $start, ($end-$start));
      }
      while ($claims_text =~/antagonist/ig) {
        $phrases{19}=1;
        my $start = $-[0]-123; if ($start<0) {$start =0;}
        push @{ $claims{19}}, substr($claims_text, $start, $+[0]-$start);
      }
      while ($claims_text =~/\bagonist/ig) {
        $phrases{20}=1;
        my $start = $-[0]-123; if ($start<0) {$start =0;}
        push @{ $claims{20}}, substr($claims_text, $start, $+[0]-$start);
      }
      while ($claims_text =~/selective binding compounds/ig) {
        $phrases{21}=1;
        my $start = $-[0]-123; if ($start<0) {$start =0;}
        push @{ $claims{21}}, substr($claims_text, $start, $+[0]-$start);
      }
      while ($claims_text =~/activity of/ig) {
        $phrases{24}=1;
        my $end = $+[0]+122;
        push @{ $claims{24}}, substr($claims_text, $-[0], 134);
      }
      while ($claims_text =~/antibodies/ig) {
        $phrases{25}=1;
        my $start = $-[0]-123; if ($start<0) {$start =0;}
        push @{ $claims{25}}, substr($claims_text, $start, $+[0]-$start);
      }
      while ($claims_text =~/\bactivity/ig) {
        $phrases{26}=1;
        my $start = $-[0]-123; if ($start<0) {$start =0;}
        push @{ $claims{26}}, substr($claims_text, $start, $+[0]-$start);
      }
      while ($claims_text =~/inhibitor of/ig) {
        $phrases{27}=1;
        my $end = $+[0]+122;
        push @{ $claims{27}}, substr($claims_text, $-[0], 134);
      }
      while ($claims_text =~/binding/ig) {
        $phrases{29}=1;
        my $start = $-[0]-123; if ($start<0) {$start =0;}
        push @{ $claims{29}}, substr($claims_text, $start, $+[0]-$start);
      }
      while ($claims_text =~/antibodies directed against/ig) {
        $phrases{30}=1;
        my $end = $+[0]+122;
        push @{ $claims{30}}, substr($claims_text, $-[0], 150);
      }
      while ($claims_text =~/treatment of .+? related/ig) {
        $phrases{31}=1;
        my $start = $-[0];
        my $end = $+[0];
        push @{ $claims{31}}, substr($claims_text, $start, ($end-$start));
      }
      while ($claims_text =~/antibody for/ig) {
        $phrases{32}=1;
        my $end = $+[0]+122;
        push @{ $claims{32}}, substr($claims_text, $-[0], 137);
      }
      while ($claims_text =~/anti-.+? antibody/ig) {
        $phrases{33}=1;
        my $start = $-[0];
        my $end = $+[0];
        push @{ $claims{33}}, substr($claims_text, $start, ($end-$start));
      }
      while ($claims_text =~/human anti-.+?(?!\s*antibody)/ig) {
        $phrases{34}=1;
        my $end = $+[0]+122;
        push @{ $claims{34}}, substr($claims_text, $-[0], 133);
      }
      while ($claims_text =~/antibodies to/ig) {
        $phrases{35}=1;
        my $end = $+[0]+122;
        push @{ $claims{35}}, substr($claims_text, $-[0], 136);
      }
      while ($claims_text =~/high .+? affinity/ig) {
        $phrases{36}=1;
        my $start = $-[0];
        my $end = $+[0];
        push @{ $claims{36}}, substr($claims_text, $start, ($end-$start));
      }
      while ($claims_text =~/inhibiting/ig) {
        $phrases{39}=1;
        my $end = $+[0]+122;
        push @{ $claims{39}}, substr($claims_text, $-[0], 137);
      }
      while ($claims_text =~/\bblock/ig) {
        $phrases{40}=1;
        my $end = $+[0]+122;
        push @{ $claims{40}}, substr($claims_text, $-[0], 137);
      }
      while ($claims_text =~/blocking/ig) {
        $phrases{41}=1;
        my $end = $+[0]+122;
        push @{ $claims{41}}, substr($claims_text, $-[0], 137);
      }
      while ($claims_text =~/ligand for/ig) {
        $phrases{42}=1;
        my $end = $+[0]+122;
        push @{ $claims{42}}, substr($claims_text, $-[0], 137);
      }
      while ($claims_text =~/ligands for/ig) {
        $phrases{42}=1;
        my $end = $+[0]+122;
        push @{ $claims{42}}, substr($claims_text, $-[0], 137);
      }
      while ($claims_text =~/compounds that interact with/ig) {
        $phrases{43}=1;
        my $end = $+[0]+122;
        push @{ $claims{43}}, substr($claims_text, $-[0], 137);
      }
      while ($claims_text =~/modulating the function of/ig) {
        $phrases{44}=1;
        my $end = $+[0]+122;
        push @{ $claims{44}}, substr($claims_text, $-[0], 137);
      }
      while ($claims_text =~/ligand/ig) {
        $phrases{45}=1;
        my $start = $-[0]-123; if ($start<0) {$start =0;}
        push @{ $claims{45}}, substr($claims_text, $start, $+[0]-$start);
      }
  
      if (keys %phrases == 0) {next;}
  
      foreach my $syn (sort { length($b) <=> length($a) } keys %syns) {
        $match_claim = 0;
        while ($claims_text =~/\b\Q$syn\E\b/ig) {
          my $start = $-[0];
          my $end = $+[0];
          if (scalar(keys %claims_matches) == 0) {
            $claims_matches{$syn}=1;
            $pos{lc($syn)} = {start => $-[0], end => $+[0]};
          } else {
            OUTER: foreach my $a (keys %claims_matches) {
              if (($pos{lc($a)}->{end} >= $end and $pos{lc($a)}->{start} < $start) or ($pos{lc($a)}->{start} <= $start and $pos{lc($a)}->{end} > $end)) {
                $match_claim = 1;
                last;
              }
              if ($match_claim == 0) {
                $claims_matches{$syn}=1;
                $pos{lc($syn)} = {start => $-[0], end => $+[0]};
              }
            }
          }
        }
      }
  
      if (keys %claims_matches ==0) {next;}
  
      if ($phrases{1}==1) {
        foreach my $claims_text2 (@{ $claims{1}}) {
          foreach my $syn (sort { length($b) <=> length($a) } keys %claims_matches) {
            if ($claims_text2 =~/\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*inhibitors$/ig) {
              my $append;
              if ($1 ne '') {
                if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                  $append = 'receptor';
                } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                  $append = 'kinase';
                }
                push @claims_matches, "EXACT 1: " . $syn  . " $append"; last;
              } else {
                push @claims_matches, "EXACT 1: " .$syn; last;
              }
            }
          }
        }
      }
      if ($phrases{3}==1) {
        foreach my $claims_text2 (@{ $claims{3}}) {
          foreach my $syn (sort { length($b) <=> length($a) } keys %claims_matches) {
            if ($claims_text2 =~/^inhibitors of (?:soluble|the human|human)?\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig) {
              my $append;
              if ($1 ne '') {
                if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                  $append = 'receptor';
                } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                  $append = 'kinase';
                }
                push @claims_matches, "EXACT 3: " .$syn . " $append"; last;
              } else {
                push @claims_matches, "EXACT 3: " .$syn; last;
              }
            }
          }
        }
      }
      if ($phrases{4}==1) {
        foreach my $claims_text2 (@{ $claims{4}}) {
          foreach my $syn (sort { length($b) <=> length($a) } keys %claims_matches) {
            if ($claims_text2 =~/\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*inhibitor\b$/ig) {
              my $append;
              if ($1 ne '') {
                if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                  $append = 'receptor';
                } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                  $append = 'kinase';
                }
                  push @claims_matches, "EXACT 4: " .$syn. " $append"; last;
              } else {
                push @claims_matches, "EXACT 4: " .$syn; last;
              }
            }
          }
        }
      }
      if ($phrases{5} == 1) {
        foreach my $claims_text2 (@{ $claims{5}}) {
          foreach my $syn (sort { length($b) <=> length($a) } keys %claims_matches) {
            if ($claims_text2 =~/^modulators of\s*(?:the)?\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig) {
              my $append;
              if ($1 ne '') {
                if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                  $append = 'receptor';
                } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                  $append = 'kinase';
                }
                push @claims_matches, "EXACT 5: " .$syn. " $append"; last;
              } else {
                push @claims_matches, "EXACT 5: " .$syn; last;
              }
            }
          }
        }
      }
      if ($phrases{6} == 1) {
        foreach my $claims_text2 (@{ $claims{6}}) {
          foreach my $syn (sort { length($b) <=> length($a) } keys %claims_matches) {
            if ($claims_text2 =~/^modulation of\s*(?:the)?\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig) {
              my $append;
              if ($1 ne '') {
                if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                  $append = 'receptor';
                } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                  $append = 'kinase';
                }
                push @claims_matches, "EXACT 6: " .$syn. " $append"; last;
              } else {
                push @claims_matches, "EXACT 6: " .$syn; last;
              }
            }
          }
        }
      }
      if ($phrases{7} == 1) {
        foreach my $claims_text2 (@{ $claims{7}}) {
          foreach my $syn (sort { length($b) <=> length($a) } keys %claims_matches) {
            if ($claims_text2 =~/^targeting\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig) {
              my $append;
              if ($1 ne '') {
                if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                  $append = 'receptor';
                } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                  $append = 'kinase';
                }
                push @claims_matches, "EXACT 7: " .$syn. " $append"; last;
              } else {
                  push @claims_matches, "EXACT 7: " .$syn; last;
              }
            }
          }
        }
      }
      if ($phrases{8} == 1) {
        foreach my $claims_text2 (@{ $claims{8}}) {
          foreach my $syn (sort { length($b) <=> length($a) } keys %claims_matches) {
            if ($claims_text2 =~/\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*modulators$/ig) {
              my $append;
              if ($1 ne '') {
                if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                  $append = 'receptor';
                } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                  $append = 'kinase';
                }
                push @claims_matches, "EXACT 8: " .$syn. " $append"; last;
              } else {
                push @claims_matches, "EXACT 8: " .$syn; last;
              }
            }
          }
        }
      }
      if ($phrases{9} == 1) {
        foreach my $claims_text2 (@{ $claims{9}}) {
          foreach my $syn (sort { length($b) <=> length($a) } keys %claims_matches) {
            if ($claims_text2 =~/^binding specifically to\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig) {
              my $append;
              if ($1 ne '') {
                if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                  $append = 'receptor';
                } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                  $append = 'kinase';
                }
                push @claims_matches, "EXACT 9: " .$syn. " $append"; last;
              } else {
                  push @claims_matches, "EXACT 9: " .$syn; last;
              }
            }
          }
        }
      }
      if ($phrases{12} == 1) {
        foreach my $claims_text2 (@{ $claims{12}}) {
          foreach my $syn (sort { length($b) <=> length($a) } keys %claims_matches) {
            if ($claims_text2 =~/\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*mutants$/ig) {
              my $append;
              if ($1 ne '') {
                if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                  $append = 'receptor';
                } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                  $append = 'kinase';
                }
                push @claims_matches, "EXACT 12: " .$syn. " $append"; last;
              } else {
                push @claims_matches, "EXACT 12: " .$syn; last;
              }
            }
          }
        }
      }
      if ($phrases{13} == 1) {
        foreach my $claims_text2 (@{ $claims{13}}) {
          foreach my $syn (sort { length($b) <=> length($a) } keys %claims_matches) {
            if ($claims_text2 =~/^inhibit\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig) {
              my $append;
              if ($1 ne '') {
                if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                  $append = 'receptor';
                } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                  $append = 'kinase';
                }
                push @claims_matches, "EXACT 13: " .$syn. " $append"; last;
              } else {
                push @claims_matches, "EXACT 13: " .$syn; last;
              }
            }
          }
        }
      }
      if ($phrases{14} == 1) {
        foreach my $claims_text2 (@{ $claims{14}}) {
          foreach my $syn (sort { length($b) <=> length($a) } keys %claims_matches) {
            if ($claims_text2 =~/(?:^monoclonal antibodies|^antibodies)\s*recogni(?:z|s)ing\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig) {
              my $append;
              if ($1 ne '') {
                if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                  $append = 'receptor';
                } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                  $append = 'kinase';
                }
                push @claims_matches, "EXACT 14: " .$syn. " $append"; last;
              } else {
                push @claims_matches, "EXACT 14: " .$syn; last;
              }
            }
          }
        }
      }
      if ($phrases{17} == 1) {
        foreach my $claims_text2 (@{ $claims{17}}) {
          foreach my $syn (sort { length($b) <=> length($a) } keys %claims_matches) {
            if ($claims_text2 =~/^modulating the\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig) {
              my $append;
              if ($1 ne '') {
                if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                  $append = 'receptor';
                } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                  $append = 'kinase';
                }
                push @claims_matches, "EXACT 17: " .$syn. " $append"; last;
              } else {
                push @claims_matches, "EXACT 17: " .$syn; last;
              }
            }
          }
        }
      }
      if ($phrases{18} == 1) {
        foreach my $claims_text2 (@{ $claims{18}}) {
          foreach my $syn (sort { length($b) <=> length($a) } keys %claims_matches) {
            if ($claims_text2 =~/^selective\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*inhibitors/ig) {
              my $append;
              if ($1 ne '') {
                if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                  $append = 'receptor';
                } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                  $append = 'kinase';
                }
                push @claims_matches, "EXACT 18: " .$syn. " $append"; last;
              } else {
                push @claims_matches, "EXACT 18: " .$syn; last;
              }
            }
          }
        }
      }
      if ($phrases{19} == 1) {
        foreach my $claims_text2 (@{ $claims{19}}) {
          foreach my $syn (sort { length($b) <=> length($a) } keys %claims_matches) {
            if ($claims_text2 =~/\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*(?:non competitive|non-competitive|competitive)?\s*(?:antagonists|antagonist\b)$/ig) {
              my $append;
              if ($1 ne '') {
                if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                  $append = 'receptor';
                } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                  $append = 'kinase';
                }
                push @claims_matches, "EXACT 19: " .$syn. " $append"; last;
              } else {
                push @claims_matches, "EXACT 19: " .$syn; last;
              }
            }
          }
        }
      }
      if ($phrases{20} == 1) {
        foreach my $claims_text2 (@{ $claims{20}}) {
          foreach my $syn (sort { length($b) <=> length($a) } keys %claims_matches) {
            if ($claims_text2 =~/\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*(?:agonist|agonists|partial agonist|partial agonists|inverse agonist|inverse agonists)$/ig) {
              my $append;
              if ($1 ne '') {
                if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                  $append = 'receptor';
                } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                  $append = 'kinase';
                }
                push @claims_matches, "EXACT 20: " .$syn. " $append"; last;
              } else {
                push @claims_matches, "EXACT 20: " .$syn; last;
              }
            }
          }
        }
      }
      if ($phrases{21} == 1) {
        foreach my $claims_text2 (@{ $claims{21}}) {
          foreach my $syn (sort { length($b) <=> length($a) } keys %claims_matches) {
            if ($claims_text2 =~/\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*selective binding compounds$/ig) {
              my $append;
              if ($1 ne '') {
                if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                  $append = 'receptor';
                } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                  $append = 'kinase';
                }
                push @claims_matches, "EXACT 21: " .$syn. " $append"; last;
              } else {
                push @claims_matches, "EXACT 21: " .$syn; last;
              }
            }
          }
        }
      }
      if ($phrases{24} == 1) {
        foreach my $claims_text2 (@{ $claims{24}}) {
          foreach my $syn (sort { length($b) <=> length($a) } keys %claims_matches) {
            if ($claims_text2 =~/^activity of\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig) {
              my $append;
              if ($1 ne '') {
                if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                  $append = 'receptor';
                } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                  $append = 'kinase';
                }
                push @claims_matches, "EXACT 24: " .$syn. " $append"; last;
              } else {
                push @claims_matches, "EXACT 24: " .$syn; last;
              }
            }
          }
        }
      }
      if ($phrases{25} == 1) {
        foreach my $claims_text2 (@{ $claims{25}}) {
          foreach my $syn (sort { length($b) <=> length($a) } keys %claims_matches) {
            if ($claims_text2 =~/(?:anti-)?\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*(?:specific)?\s*(?:monoclonal antibodies|antibodies)/ig) {
              my $append;
              if ($1 ne '') {
                if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                  $append = 'receptor';
                } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                  $append = 'kinase';
                }
                push @claims_matches, "EXACT 25: " .$syn. " $append"; last;
              } else {
                push @claims_matches, "EXACT 25: " .$syn; last;
              }
            }
          }
        }
      }
      if ($phrases{26} == 1) {
        foreach my $claims_text2 (@{ $claims{26}}) {
          foreach my $syn (sort { length($b) <=> length($a) } keys %claims_matches) {
            if ($claims_text2 =~/\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*(?:inhibitory|inhibiting|antagonistic)?\s*\bactivity$/ig)  {
              my $append;
              if ($1 ne '') {
                if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                  $append = 'receptor';
                } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                  $append = 'kinase';
                }
                push @claims_matches, "EXACT 26: " .$syn. " $append"; last;
              } else {
                push @claims_matches, "EXACT 26: " .$syn; last;
              }
            }
          }
        }
      }
      if ($phrases{27} == 1) {
        foreach my $claims_text2 (@{ $claims{27}}) {
          foreach my $syn (sort { length($b) <=> length($a) } keys %claims_matches) {
            if ($claims_text2 =~/^inhibitor of\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig)  {
              my $append;
              if ($1 ne '') {
                if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                  $append = 'receptor';
                } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                  $append = 'kinase';
                }
                push @claims_matches, "EXACT 27: " .$syn. " $append"; last;
              } else {
                push @claims_matches, "EXACT 27: " .$syn;
              }
            }
          }
        }
      }
      if ($phrases{29} == 1) {
        foreach my $claims_text2 (@{ $claims{29}}) {
          foreach my $syn (sort { length($b) <=> length($a) } keys %claims_matches) {
            if ($claims_text2 =~/\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*binding$/ig) {
              my $append;
              if ($1 ne '') {
                if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                  $append = 'receptor';
                } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                  $append = 'kinase';
                }
                push @claims_matches, "EXACT 29: " .$syn. " $append"; last;
              } else {
                push @claims_matches, "EXACT 29: " .$syn; last;
              }
            }
          }
        }
      }
      if ($phrases{30} == 1) {
        foreach my $claims_text2 (@{ $claims{30}}) {
          foreach my $syn (sort { length($b) <=> length($a) } keys %claims_matches) {
            if ($claims_text2 =~/(?:monoclonal antibodies|antibodies)\s*directed against\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig) {
              my $append;
              if ($1 ne '') {
                if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                  $append = 'receptor';
                } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                  $append = 'kinase';
                }
                push @claims_matches, "EXACT 30: " .$syn. " $append"; last;
              } else {
                push @claims_matches, "EXACT 30: " .$syn; last;
              }
            }
          }
        }
      }
      if ($phrases{31} == 1) {
        foreach my $claims_text2 (@{ $claims{31}}) {
          foreach my $syn (sort { length($b) <=> length($a) } keys %claims_matches) {
            if ($claims_text2 =~/treatment of\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*related/ig) {
              my $append;
              if ($1 ne '') {
                if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                  $append = 'receptor';
                } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                  $append = 'kinase';
                }
                push @claims_matches, "EXACT 31: " .$syn. " $append"; last;
              } else {
                push @claims_matches, "EXACT 31: " .$syn; last;
              }
            }
          }
        }
      }
      if ($phrases{32} ==1) {
        foreach my $claims_text2 (@{ $claims{32}}) {
          foreach my $syn (sort { length($b) <=> length($a) } keys %claims_matches) {
            if ($claims_text2 =~/(?:monoclonal antibody|antibody)\s*for\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig)  {
              my $append;
              if ($1 ne '') {
                if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                  $append = 'receptor';
                } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                  $append = 'kinase';
                }
                push @claims_matches, "EXACT 32: " .$syn. " $append"; last;
              } else {
                push @claims_matches, "EXACT 32: " .$syn; last;
              }
            }
          }
        }
      }
      if ($phrases{33} == 1) {
        foreach my $claims_text2 (@{ $claims{33}}) {
          foreach my $syn (sort { length($b) <=> length($a) } keys %claims_matches) {
            if ($claims_text2 =~/anti-\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*(?:monoclonal antibody|antibody)/ig) {
              my $append;
              if ($1 ne '') {
                if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                  $append = 'receptor';
                } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                    $append = 'kinase';
                }
                  push @claims_matches, "EXACT 33: " .$syn. " $append"; last;
              } else {
                  push @claims_matches, "EXACT 33: " .$syn; last;
              }
            }
          }
        }
      }
      if ($phrases{34} == 1) {
        foreach my $claims_text2 (@{ $claims{34}}) {
          foreach my $syn (sort { length($b) <=> length($a) } keys %claims_matches) {
            if ($claims_text2 =~/^human anti-\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig) {
              my $append;
              if ($1 ne '') {
                if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                  $append = 'receptor';
                } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                  $append = 'kinase';
                }
                push @claims_matches, "EXACT 34: " .$syn. " $append"; last;
              } else {
                push @claims_matches, "EXACT 34: " .$syn; last;
              }
            }
          }
        }
      }
      if ($phrases{35} == 1) {
        foreach my $claims_text2 (@{ $claims{35}}) {
          foreach my $syn (sort { length($b) <=> length($a) } keys %claims_matches) {
            if ($claims_text2 =~/(?:monoclonal antibodies|antibodies)\s*to\s*(?:human)?\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig) {
              my $append;
              if ($1 ne '') {
                if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                  $append = 'receptor';
                } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                  $append = 'kinase';
                }
                push @claims_matches, "EXACT 35: " .$syn. " $append"; last;
              } else {
                push @claims_matches, "EXACT 35: " .$syn; last;
              }
            }
          }
        }
      }
      if ($phrases{36} == 1) {
        foreach my $claims_text2 (@{ $claims{36}}) {
          foreach my $syn (sort { length($b) <=> length($a) } keys %claims_matches) {
            if ($claims_text2 =~/high\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*affinity/ig) {
              my $append;
              if ($1 ne '') {
                if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                  $append = 'receptor';
                } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                  $append = 'kinase';
                }
                push @claims_matches, "EXACT 36: " .$syn. " $append"; last;
              } else {
                push @claims_matches, "EXACT 36: " .$syn; last;
              }
            }
          }
        }
      }
      if ($phrases{39} == 1) {
        foreach my $claims_text2 (@{ $claims{39}}) {
          foreach my $syn (sort { length($b) <=> length($a) } keys %claims_matches) {
            if ($claims_text2 =~/^inhibiting\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig) {
              my $append;
              if ($1 ne '') {
                if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                  $append = 'receptor';
                } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                  $append = 'kinase';
                }
                push @claims_matches, "EXACT 39: " .$syn . " $append"; last;
              } else {
                 push @claims_matches, "EXACT 39: " .$syn; last;
              }
            }
          }
        }
      }
      if ($phrases{40}==1) {
        foreach my $claims_text2 (@{ $claims{40}}) {
          foreach my $syn (sort { length($b) <=> length($a) } keys %claims_matches) {
            if ($claims_text2 =~/^(?:blocks\b|block\b)\s*(?:the)?\s*\b\Q$syn\E\b(receptor|kinase|receptors|kinases)?/ig) {
              my $append;
              if ($1 ne '') {
                if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                  $append = 'receptor';
                } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                  $append = 'kinase';
                }
                push @claims_matches, "EXACT 40: " .$syn . " $append";  last;
              } else {
                push @claims_matches, "EXACT 40: " .$syn;  last;
              }
            }
          }
        }
      }
      if ($phrases{41}==1) {
        foreach my $claims_text2 (@{ $claims{41}}) {
          foreach my $syn (sort { length($b) <=> length($a) } keys %claims_matches) {
            if ($claims_text2 =~/^blocking\b\s*(?:the\b|a\b|an\b)?\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig) {
              my $append;
              if ($1 ne '') {
                if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                  $append = 'receptor';
                } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                  $append = 'kinase';
                }
                push @claims_matches, "EXACT 41: " .$syn . " $append";  last;
              } else {
                push @claims_matches, "EXACT 41: " .$syn;  last;
              }
            }
          }
        }
      }
      if ($phrases{42}==1) {
        foreach my $claims_text2 (@{ $claims{42}}) {
          foreach my $syn (sort { length($b) <=> length($a) } keys %claims_matches) {
            if ($claims_text2 =~/^(?:ligand|ligands)\s*(?:for the\b|for\b)\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig) {
              my $append;
              if ($1 ne '') {
                if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                  $append = 'receptor';
                } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                  $append = 'kinase';
                }
                push @claims_matches, "EXACT 42: " .$syn . " $append";  last;
              } else {
                push @claims_matches, "EXACT 42: " .$syn;  last;
              }
            }
          }
        }
      }
      if ($phrases{43}==1) {
        foreach my $claims_text2 (@{ $claims{43}}) {
          foreach my $syn (sort { length($b) <=> length($a) } keys %claims_matches) {
            if ($claims_text2 =~/^compounds that interact with (?:the\b)?\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig) {
              my $append;
              if ($1 ne '') {
                if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                  $append = 'receptor';
                } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                  $append = 'kinase';
                }
                push @claims_matches, "EXACT 43: " .$syn . " $append"; last;
              } else {
                push @claims_matches, "EXACT 43: " .$syn;  last;
              }
            }
          }
        }
      }
      if ($phrases{44}==1) {
        foreach my $claims_text2 (@{ $claims{44}}) {
          foreach my $syn (sort { length($b) <=> length($a) } keys %claims_matches) {
            if ($claims_text2 =~/^modulating the function of\s*(?:a\b|an\b|the\b)?\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig) {
              my $append;
              if ($1 ne '') {
                if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                  $append = 'receptor';
                } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                  $append = 'kinase';
                }
                push @claims_matches, "EXACT 44: " .$syn . " $append"; last;
              } else {
                push @claims_matches, "EXACT 44: " .$syn;  last;
              }
            }
          }
        }
      }
      if ($phrases{45}==1) {
        foreach my $claims_text2 (@{ $claims{45}}) {
          foreach my $syn (sort { length($b) <=> length($a) } keys %claims_matches) {
            if ($claims_text2 =~/\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*(?:ligand\b|ligands)\b$/ig) {
              my $append;
              if ($1 ne '') {
                if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                  $append = 'receptor';
                } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                  $append = 'kinase';
                }
                push @claims_matches, "EXACT 45: " .$syn . " $append"; last;
              } else {
                push @claims_matches, "EXACT 45: " .$syn;  last;
              }
            }
          }
        }
      }
    }

#-----
    foreach my $t (@description_matches) {
      if ($t =~/EXACT \d+:/) {
        push @exact, "DESCRIPTION " . $t;
      } elsif ($t =~/FREE \d+:/) {
        push @free, "DESCRIPTION " . $t;
      }
    }
    foreach my $c (@claims_matches) {
      if ($c =~/EXACT \d+:/) {
        push @exact, "CLAIMS " . $c;
      } elsif ($c =~/FREE \d+:/) {
        push @free, "CLAIMS " . $c;
      }
    }
    print RESULT $npat->to_literal() . "\n";
    if (scalar @exact > 0) {
      foreach my $e (@exact) {
        print RESULT "$e\n";
      }
    } elsif (scalar @exact == 0 and scalar @free > 0) {
      foreach my $f (@free) {
        print RESULT "$f\n";
      }
    }
    @exact = ();
    @free = ();
  }
}
