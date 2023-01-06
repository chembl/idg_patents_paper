#!/usr/bin/perl
use 5.010;
use strict;
use POSIX;
use XML::LibXML;;

$ENV{'NLS_LANG'} = 'AMERICAN_AMERICA.AL32UTF8';
my $max_file_index = $ARGV[0];

open(TSYN, "<all_tdark_tbio_2022_list"); #file with the list of targets to search for

$| = 1;

my $file_index;
for (my $i = 1; $i <= $max_file_index; $i++) {
  $file_index = $i;

  open(RESULT, ">title_$file_index");

  my %syns;

  while (my $line =<TSYN>) {
    chomp($line);
    $syns{lc($line)} = 1;
  }
 
  my $npat_per_file = 750;
  my $npat_per_dir = 750;

  my $dir_index = ceil($file_index*$npat_per_file/$npat_per_dir);
  my $dir = "downloaded_patents/downloaded_patents_" . sprintf("%04d", $dir_index);

  opendir(LASTUPD, "$dir"); #directory with the patents
  open(PAT_LIST, "<downloaded_patents/pat_lists/pat_list_$file_index");

  my %pat_list;

  while (my $line = <PAT_LIST>) {
    chomp($line);
    my $id = $line;
    $pat_list{$id}=1;
  }

  while (my $filename =  readdir LASTUPD) {
    if ($filename !~/\.xml/) {next;}
    if (!exists $pat_list{$filename}) {next;}

    my $dom = XML::LibXML->load_xml(location => "$dir/$filename");
    my @title_matches;
    my @abstract_matches;
    my $found = 0;
    my $title_text;
    my $abstract_text;
    my %start_or_end;
    my %title_matches;
    my %abstract_matches;
    my @pos_title;
    my @exact;
    my @free;

    foreach my $npat ($dom->findnodes('/patent-document/@ucid')) {
      $found = 0;
      @title_matches = ();
  
      undef %title_matches;
      undef %abstract_matches;
      my $match_title;  
      my %start;
      my %end;
      my @matches_positions_title;

      foreach my $title ($npat->findnodes('//invention-title[@lang="EN"]')) {
        $title_text = $title->to_literal();
        foreach my $syn (sort { length($b) <=> length($a) } keys %syns) {
          $match_title = 0;
          @matches_positions_title =();
          while ($title_text =~/\b\Q$syn\E\b/ig) {
            my $start = $-[0];
            my $end = $+[0];
            push @matches_positions_title, {'syn'=>lc($syn), 'start'=>$start, 'end'=>$end, 'discard'=>0};
            if (scalar(keys %title_matches) == 0) {
              $title_matches{lc($syn)}=1;
              push @pos_title, {'syn'=>lc($syn), 'start'=>$start, 'end'=>$end};
            } else {
              OUTER: foreach my $p (@pos_title) {
                foreach my $mp (@matches_positions_title) {
                  if (($p->{end} >= $mp->{end} and $p->{start} < $mp->{start}) or ($p->{start} <= $mp->{start} and $p->{end} > $mp->{end})) {
                    splice @matches_positions_title;
                  }
                }
              }
              foreach my $mp2 (@matches_positions_title) {
                if ($mp2->{discard}==0) {
                  push @pos_title, {'syn'=>lc($syn), 'start'=>$-[0], 'end'=>$+[0]};
                  $title_matches{lc($syn)} = 1;
                }
              }
            }
          }
        }
        $found=0; undef %start_or_end;
        $title_text = $title->to_literal();
        if ($title_text =~/.+? inhibitors/i) {
          my @count_matches = ($title_text=~/.+? inhibitors/ig); 
          my $count_matches = @count_matches;
          foreach my $syn (sort { length($b) <=> length($a) } keys %title_matches) {
            if (($title_text =~/\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*inhibitors/i) and $start_or_end{$+[0]}==0) {
              $start_or_end{$+[0]} = 1;
              my @count_matches_syn2 = ($title_text =~/\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*inhibitors/ig);
              my $count_matches_syn2 = @count_matches_syn2;
              for ( my $i = 1; $i < $count_matches_syn2 + 1; $i++ ) {
                my $append;
                if ($1 ne '') {
                  if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                    $append = 'receptor';
                  } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                    $append = 'kinase';
                  }
                  push @title_matches, "TITLE EXACT 1: " .$syn . " $append";
                } else {
                  push @title_matches, "TITLE EXACT 1: " .$syn;
                }
                $found = $found + $count_matches_syn2;
              }
            }
            if ($found == $count_matches) {
              last;
            }
          }
          if ($found <$count_matches) {
            my @matches = $title_text =~/(?:((?:\S+)(?:\s*receptor|\s*kinase|\s*receptors|\s*kinases)?))\s*inhibitors\b/ig;
            foreach my $m (@matches) {
              if (length($m)>2 and lc($m) ne 'the' and !grep(/^EXACT 1: \Q$m\E$/i, @title_matches)) {push @title_matches, "TITLE FREE 1: " . $m;};
            }
            $found = 0;
          }
        }
        $found=0; undef %start_or_end;
        $title_text = $title->to_literal();
        if ($title_text =~/inhibitors of .+/i) {
          my @count_matches = ($title_text =~/inhibitors of (?:soluble|the human|human)?\b.+?/ig); 
          my $count_matches = @count_matches;
          foreach my $syn (sort { length($b) <=> length($a) } keys %title_matches) {
            if (($title_text =~/inhibitors of (?:soluble|the human|human)?\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/i) and $start_or_end{$-[0]}==0) {
              $start_or_end{$+[0]} = 1;
              my @count_matches_syn2 = ($title_text =~/inhibitors of (?:soluble|the human|human)?\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig);
              my $count_matches_syn2 = @count_matches_syn2;
              for ( my $i = 1; $i < $count_matches_syn2 + 1; $i++ ) {
                my $append;
                if ($1 ne '') {
                  if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                    $append = 'receptor';
                  } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                    $append = 'kinase';
                  }
                  push @title_matches, "TITLE EXACT 3: " .$syn . " $append";
                } else {
                  push @title_matches, "TITLE EXACT 3: " .$syn;
                }
                $found = $found + $count_matches_syn2;
              }
            }
            if ($found == $count_matches) {
              last;
            }
          }
          if ($found <$count_matches) {
            my @matches = $title_text =~/inhibitors of (?:soluble|the human|human)?\b((?:\S+)(?:\s*receptor|\s*kinase|\s*receptors|\s*kinases)?)/ig;
            foreach my $m (@matches) {
              if (length($m)>2 and lc($m) ne 'the' and !grep(/^EXACT 3: \Q$m\E$/i, @title_matches)) {push @title_matches, "TITLE FREE 3: " . $m;};
            }
            $found = 0;
          }
        }
        $found=0; undef %start_or_end;
        $title_text = $title->to_literal();
        if ($title_text =~/.+? inhibitor\b/i) {
          my @count_matches = ($title_text =~/.+? inhibitor\b/ig); 
          my $count_matches = @count_matches;
          foreach my $syn (sort { length($b) <=> length($a) } keys %title_matches) {
            if (($title_text =~/\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*inhibitor\b/i) and $start_or_end{$+[0]}==0) {
              $start_or_end{$+[0]} = 1;
              my @count_matches_syn2 = ($title_text =~/\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*inhibitor\b/ig);
              my $count_matches_syn2 = @count_matches_syn2;
              for ( my $i = 1; $i < $count_matches_syn2 + 1; $i++ ) {
                my $append;
                if ($1 ne '') {
                  if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                    $append = 'receptor';
                  } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                    $append = 'kinase';
                  }
                  push @title_matches, "TITLE EXACT 4: " .$syn . " $append";
                } else {
                  push @title_matches, "TITLE EXACT 4: " .$syn;
                }
                $found = $found + $count_matches_syn2;
              }
            }
            if ($found == $count_matches) {
              last;
            }
          }
          if ($found <$count_matches) {
            my @matches = $title_text =~/((?:\S+)(?:\s*receptor|\s*kinase|\s*receptors|\s*kinases)?)\s*inhibitor\b/ig;
            foreach my $m (@matches) {
              if (length($m)>2 and lc($m) ne 'the' and !grep(/^EXACT 4: \Q$m\E$/i, @title_matches)) {push @title_matches, "TITLE FREE 4: " . $m;};
            }
            $found = 0;
          }
        }
        $found=0; undef %start_or_end;
        $title_text = $title->to_literal();
        if ($title_text =~/modulators of .+?/i) {
          my @count_matches = ($title_text =~/modulators of .+?/ig); 
          my $count_matches = @count_matches;
          foreach my $syn (sort { length($b) <=> length($a) } keys %title_matches) {
            if (($title_text =~/modulators of\s*(?:the)?\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/i) and $start_or_end{$-[0]}==0) {
              $start_or_end{$+[0]} = 1;
              my @count_matches_syn2 = ($title_text =~/modulators of\s*(?:the)?\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig);
              my $count_matches_syn2 = @count_matches_syn2;
              for ( my $i = 1; $i < $count_matches_syn2 + 1; $i++ ) {
                my $append;
                if ($1 ne '') {
                  if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                    $append = 'receptor';
                  } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                    $append = 'kinase';
                  }
                  push @title_matches, "TITLE EXACT 5: " .$syn . " $append";
                } else {
                  push @title_matches, "TITLE EXACT 5: " .$syn;
                }
                $found = $found + $count_matches_syn2;
              }
            }
            if ($found == $count_matches) {
              last;
            }
          }
          if ($found <$count_matches) {
            my @matches = $title_text =~/modulators of\s*(?:the)?\s*((?:\S+)(?:\s*receptor|\s*kinase|\s*receptors|\s*kinases)?)/ig;
            foreach my $m (@matches) {
              if (length($m)>2 and lc($m) ne 'the' and !grep(/^EXACT 5: \Q$m\E$/i, @title_matches)) {push @title_matches, "TITLE FREE 5: " . $m;};
            }
            $found = 0;
          }      
        }
        $found=0; undef %start_or_end;
        $title_text = $title->to_literal();
        if ($title_text =~/modulation of .+?/i) {
          my @count_matches = ($title_text =~/modulation of .+?/ig); 
          my $count_matches = @count_matches;
          foreach my $syn (sort { length($b) <=> length($a) } keys %title_matches) {
            if (($title_text =~/modulation of\s*(?:the)?\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/i) and $start_or_end{$-[0]}==0) {
              $start_or_end{$+[0]} = 1;
              my @count_matches_syn2 = ($title_text =~/modulation of\s*(?:the)?\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig);
              my $count_matches_syn2 = @count_matches_syn2;
              for ( my $i = 1; $i < $count_matches_syn2 + 1; $i++ ) {
                my $append;
                if ($1 ne '') {
                  if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                    $append = 'receptor';
                  } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                    $append = 'kinase';
                  }
                  push @title_matches, "TITLE EXACT 6: " .$syn . " $append";
                } else {
                  push @title_matches, "TITLE EXACT 6: " .$syn;
                }
                $found = $found + $count_matches_syn2;
              }
            }
            if ($found == $count_matches) {
              last;
            }
          }
          if ($found <$count_matches) {
            my @matches = $title_text =~/modulation of\s*(?:the)?\s*((?:\S+)(?:\s*receptor|\s*kinase|\s*receptors|\s*kinases)?)/ig;
            foreach my $m (@matches) {
              if (length($m)>2 and lc($m) ne 'the' and !grep(/^EXACT 6: \Q$m\E$/i, @title_matches)) {push @title_matches, "TITLE FREE 6: " . $m;};
            }
            $found = 0;
          }
        }
        $found=0; undef %start_or_end;
        $title_text = $title->to_literal();
        if ($title_text =~/targeting .+?/i) {
          my @count_matches = ($title_text =~/targeting .+?/ig); 
          my $count_matches = @count_matches;
          foreach my $syn (sort { length($b) <=> length($a) } keys %title_matches) {
            if (($title_text =~/targeting\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/i) and $start_or_end{$-[0]}==0) {
              $start_or_end{$+[0]} = 1;
              my @count_matches_syn2 = ($title_text =~/targeting\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig);
              my $count_matches_syn2 = @count_matches_syn2;
              for ( my $i = 1; $i < $count_matches_syn2 + 1; $i++ ) {
                my $append;
                if ($1 ne '') {
                  if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                    $append = 'receptor';
                  } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                    $append = 'kinase';
                  }
                  push @title_matches, "TITLE EXACT 7: " .$syn . " $append";
                } else {
                  push @title_matches, "TITLE EXACT 7: " .$syn;
                }
                $found = $found + $count_matches_syn2;
              }
            }
            if ($found == $count_matches) {
              last;
            }
          }
          if ($found <$count_matches) {
            my @matches = $title_text =~/targeting\s*((?:\S+)(?:\s*receptor|\s*kinase|\s*receptors|\s*kinases)?)/ig;
            foreach my $m (@matches) {
              if (length($m)>2 and lc($m) ne 'the' and !grep(/^EXACT 7: \Q$m\E$/i, @title_matches)) {push @title_matches, "TITLE FREE 7: " . $m;};
            }
            $found = 0;
          }
        }
        $found=0; undef %start_or_end;
        $title_text = $title->to_literal();
        if ($title_text =~/.+? modulators/i) {
          my @count_matches = ($title_text =~/.+? modulators/ig); 
          my $count_matches = @count_matches;
          foreach my $syn (sort { length($b) <=> length($a) } keys %title_matches) {
            if (($title_text =~/\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*modulators/i) and $start_or_end{$+[0]}==0){
              $start_or_end{$+[0]} = 1;
              my @count_matches_syn2 = ($title_text =~/\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*modulators/ig);
              my $count_matches_syn2 = @count_matches_syn2;
              for ( my $i = 1; $i < $count_matches_syn2 + 1; $i++ ) {
                my $append;
                if ($1 ne '') {
                  if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                    $append = 'receptor';
                  } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                    $append = 'kinase';
                  }
                  push @title_matches, "TITLE EXACT 8: " .$syn . " $append";
                } else {
                  push @title_matches, "TITLE EXACT 8: " .$syn;
                }
                $found = $found + $count_matches_syn2;
              }
            }
            if ($found == $count_matches) {
              last;
            }
          }  
          if ($found <$count_matches) {
            my @matches = $title_text =~/((?:\S+)(?:\s*receptor|\s*kinase|\s*receptors|\s*kinases)?)\s*modulators/ig;
            foreach my $m (@matches) {
              if (length($m)>2 and lc($m) ne 'the' and !grep(/^EXACT 8: \Q$m\E$/i, @title_matches)) {push @title_matches, "TITLE FREE 8: " . $m;};
            }
            $found = 0;
          }
        }
        $found=0; undef %start_or_end;
        $title_text = $title->to_literal();
        if ($title_text =~/binding specifically to .+?/i) {
          my @count_matches = ($title_text =~/binding specifically to .+?/ig); 
          my $count_matches = @count_matches;
          foreach my $syn (sort { length($b) <=> length($a) } keys %title_matches) {
            if (($title_text =~/binding specifically to\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/i) and $start_or_end{$-[0]}==0) {
              $start_or_end{$+[0]} = 1;
              my @count_matches_syn2 = ($title_text =~/binding specifically to \b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig);
              my $count_matches_syn2 = @count_matches_syn2;
              for ( my $i = 1; $i < $count_matches_syn2 + 1; $i++ ) {
                my $append;
                if ($1 ne '') {
                  if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                    $append = 'receptor';
                  } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                    $append = 'kinase';
                  }
                  push @title_matches, "TITLE EXACT 9: " .$syn . " $append";
                } else {
                  push @title_matches, "TITLE EXACT 9: " .$syn;
                }
                $found = $found + $count_matches_syn2;
              }
            }
            if ($found == $count_matches) {
              last;
            }
          }
          if ($found <$count_matches) {
            my @matches = $title_text =~/binding specifically to ((?:\S+)(?:\s*receptor|\s*kinase|\s*receptors|\s*kinases)?)/ig;
            foreach my $m (@matches) {
              if (length($m)>2 and lc($m) ne 'the' and !grep(/^EXACT 9: \Q$m\E$/i, @title_matches)) {push @title_matches, "TITLE FREE 9: " . $m;};
            }
            $found = 0;
          }
        }
        $found=0; undef %start_or_end;
        $title_text = $title->to_literal();
        if ($title_text =~/.+? mutants/i) {
          my @count_matches = ($title_text =~/.+? mutants/ig); 
          my $count_matches = @count_matches;
          foreach my $syn (sort { length($b) <=> length($a) } keys %title_matches) {
            if (($title_text =~/\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*mutants/i) and $start_or_end{$+[0]}==0){
              $start_or_end{$+[0]} = 1;
              my @count_matches_syn2 = ($title_text =~/\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*mutants/ig);
              my $count_matches_syn2 = @count_matches_syn2;
              for ( my $i = 1; $i < $count_matches_syn2 + 1; $i++ ) {
                my $append;
                if ($1 ne '') {
                  if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                    $append = 'receptor';
                  } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                    $append = 'kinase';
                  }
                  push @title_matches, "TITLE EXACT 12: " .$syn . " $append";
                } else {
                  push @title_matches, "TITLE EXACT 12: " .$syn;
                }
                $found = $found + $count_matches_syn2;
              }
            }
            if ($found == $count_matches) {
              last;
            }
          }
          if ($found <$count_matches) {
            my @matches = $title_text =~/((\S+)(?:\s*receptor|\s*kinase|\s*receptors|\s*kinases)?)\s*mutants/ig;
            foreach my $m (@matches) {
              if (length($m)>2 and lc($m) ne 'the' and !grep(/^EXACT 12: \Q$m\E$/i, @title_matches)) {push @title_matches, "TITLE FREE 12: " . $m;};
            }
            $found = 0;
          }
        }
        $found=0; undef %start_or_end;
        $title_text = $title->to_literal();
        if ($title_text =~/inhibit .+?/i) {
          my @count_matches = ($title_text =~/inhibit .+?/ig); 
          my $count_matches = @count_matches;
          foreach my $syn (sort { length($b) <=> length($a) } keys %title_matches) {
            if (($title_text =~/inhibit\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/i) and $start_or_end{$-[0]}==0){
              $start_or_end{$+[0]} = 1;
              my @count_matches_syn2 = ($title_text =~/inhibit\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig);
              my $count_matches_syn2 = @count_matches_syn2;
              for ( my $i = 1; $i < $count_matches_syn2 + 1; $i++ ) {
                my $append;
                if ($1 ne '') {
                  if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                    $append = 'receptor';
                  } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                    $append = 'kinase';
                  }
                  push @title_matches, "TITLE EXACT 13: " .$syn . " $append";
                } else {
                  push @title_matches, "TITLE EXACT 13: " .$syn;
                }
                $found = $found + $count_matches_syn2;
              }
            }
            if ($found == $count_matches) {
              last;
            }
          }
          if ($found <$count_matches) {
            my @matches = $title_text =~/inhibit\s*((?:\S+)(?:\s*receptor|\s*kinase|\s*receptors|\s*kinases)?)/ig;
            foreach my $m (@matches) {
              if (length($m)>2 and lc($m) ne 'the' and !grep(/^EXACT 13: \Q$m\E$/i, @title_matches)) {push @title_matches, "TITLE FREE 13: " . $m;};
            }
            $found = 0;
          }
        }
        $found=0; undef %start_or_end;
        $title_text = $title->to_literal();
        if ($title_text =~/antibodies recogni(s|z)ing .+?/i) {
          my @count_matches = ($title_text =~/antibodies recogni(?:s|z)ing .+?/ig); 
          my $count_matches = @count_matches;
          foreach my $syn (sort { length($b) <=> length($a) } keys %title_matches) {
            if (($title_text =~/(?:monoclonal antibodies|antibodies)\s*recogni(?:z|s)ing\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/i) and $start_or_end{$-[0]}==0) {
              $start_or_end{$+[0]} = 1;
              my @count_matches_syn2 = ($title_text =~/(?:monoclonal antibodies|antibodies)\s*recogni(?:z|s)ing\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig);
              my $count_matches_syn2 = @count_matches_syn2;
              for ( my $i = 1; $i < $count_matches_syn2 + 1; $i++ ) {
                my $append;
                if ($1 ne '') {
                  if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                    $append = 'receptor';
                  } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                    $append = 'kinase';
                  }
                  push @title_matches, "TITLE EXACT 14: " .$syn . " $append";
                } else {
                  push @title_matches, "TITLE EXACT 14: " .$syn;
                }
                $found = $found + $count_matches_syn2;
              }
            }
            if ($found == $count_matches) {
              last;
            }
          }
          if ($found <$count_matches) {
            my @matches = $title_text =~/antibodies recogni(?:s|z)ing\s*((?:\S+)(?:\s*receptor|\s*kinase|\s*receptors|\s*kinases)?)/ig;
            foreach my $m (@matches) {
              if (length($m)>2 and lc($m) ne 'the' and !grep(/^EXACT 14: \Q$m\E$/i, @title_matches)) {push @title_matches, "TITLE FREE 14: " . $m;};
            }
            $found =0;
          }
        }
        $found=0; undef %start_or_end;
        $title_text = $title->to_literal();
        if ($title_text =~/modulating the .+?/i) {
          my @count_matches = ($title_text =~/modulating the .+?/ig); 
          my $count_matches = @count_matches;
          foreach my $syn (sort { length($b) <=> length($a) } keys %title_matches) {
            if (($title_text =~/modulating the\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/i) and $start_or_end{$-[0]}==0) {
              $start_or_end{$+[0]} = 1;
              my @count_matches_syn2 = ($title_text =~/modulating the\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig);
              my $count_matches_syn2 = @count_matches_syn2;
              for ( my $i = 1; $i < $count_matches_syn2 + 1; $i++ ) {
                my $append;
                if ($1 ne '') {
                  if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                    $append = 'receptor';
                  } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                    $append = 'kinase';
                  }
                  push @title_matches, "TITLE EXACT 17: " .$syn . " $append";
                } else {
                  push @title_matches, "TITLE EXACT 17: " .$syn;
                }  
                $found = $found + $count_matches_syn2;
              }
            }
            if ($found == $count_matches) {
              last;
            }
          }
          if ($found <$count_matches) {
            my @matches = $title_text =~/modulating the\s*((?:\S+)(?:\s*receptor|\s*kinase|\s*receptors|\s*kinases)?)/ig;
            foreach my $m (@matches) {
              if (length($m)>2 and lc($m) ne 'the' and !grep(/^EXACT 17: \Q$m\E$/i, @title_matches)) {push @title_matches, "TITLE FREE 17: " . $m;};
            }
            $found = 0;
          }
        }
        $found=0; undef %start_or_end;
        $title_text = $title->to_literal();
        if ($title_text =~/selective .+? inhibitors/i) { 
          my @count_matches = ($title_text =~/selective .+? inhibitors/ig); 
          my $count_matches = @count_matches;
          foreach my $syn (sort { length($b) <=> length($a) } keys %title_matches) {
            if ($title_text =~/selective\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*inhibitors/i) {
              my @count_matches_syn2 = ($title_text =~/selective\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*inhibitors/ig);
              my $count_matches_syn2 = @count_matches_syn2;
              for ( my $i = 1; $i < $count_matches_syn2 + 1; $i++ ) {
                my $append;
                if ($1 ne '') {
                  if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                    $append = 'receptor';
                  } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                    $append = 'kinase';
                  }
                  push @title_matches, "TITLE EXACT 18: " .$syn . " $append";
                } else {
                  push @title_matches, "TITLE EXACT 18: " .$syn;
                }
                $found = $found + $count_matches_syn2;
              }
            }
            if ($found == $count_matches) {
              last;
            }
          }
          if ($found <$count_matches) {
            my @matches = $title_text =~/selective\s*((?:\S+)(?:\s*receptor|\s*kinase|\s*receptors|\s*kinases)?)\s*inhibitors/ig;
            foreach my $m (@matches) {
              if (length($m)>2 and lc($m) ne 'the' and !grep(/^EXACT 18: \Q$m\E$/i, @title_matches)) {push @title_matches, "TITLE FREE 18: " . $m;};
            } 
            $found =0;
          }
        }
        $found=0; undef %start_or_end;
        $title_text = $title->to_literal();
        if ($title_text =~/.+? antagonist/i) {
          my @count_matches = ($title_text =~/.+? antagonist/ig); 
          my $count_matches = @count_matches;
          foreach my $syn (sort { length($b) <=> length($a) } keys %title_matches) {
            if (($title_text =~/\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*(?:non competitive|non-competitive|competitive)?\s*(?:antagonists|antagonist\b)/i) and $start_or_end{$+[0]}==0){
              $start_or_end{$+[0]} = 1;
              my @count_matches_syn2 = ($title_text =~/\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*(?:non competitive|non-competitive|competitive)?\b(?:antagonists|antagonist\b)/ig);
              my $count_matches_syn2 = @count_matches_syn2;
              for ( my $i = 1; $i < $count_matches_syn2 + 1; $i++ ) {
                my $append;
                if ($1 ne '') {
                  if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                    $append = 'receptor';
                  } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                    $append = 'kinase';
                  }
                  push @title_matches, "TITLE EXACT 19: " .$syn . " $append";
                } else {
                  push @title_matches, "TITLE EXACT 19: " .$syn;
                }
                $found = $found + $count_matches_syn2;
              }
            }
            if ($found == $count_matches) {
              last;
            }
          }
          if ($found <$count_matches) {
            my @matches = $title_text =~/((?:\S+)(?:\s*receptor|\s*kinase|\s*receptors|\s*kinases)?)\s*(?:non competitive|non-competitive|competitive)?\s*(?:antagonists|antagonist\b)/ig;
            foreach my $m (@matches) {
              if (length($m)>2 and lc($m) ne 'the' and !grep(/^EXACT 19: \Q$m\E$/i, @title_matches)) {push @title_matches, "TITLE FREE 19: " . $m;};
            }
            $found = 0;
          }
        }
        $found=0; undef %start_or_end;
        $title_text = $title->to_literal();
        if ($title_text =~/.+? \bagonist/i) {
          my @count_matches = ($title_text =~/.+? \bagonist/ig); 
          my $count_matches = @count_matches;
          foreach my $syn (sort { length($b) <=> length($a) } keys %title_matches) {
            if (($title_text =~/\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*(?:\bagonist|\bagonists|partial agonist|partial agonists|inverse agonist|inverse agonists)/i) and $start_or_end{$+[0]}==0){
              $start_or_end{$+[0]} = 1;
              my @count_matches_syn2 = ($title_text =~/\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*(?:\bagonist|\bagonists|partial agonist|partial agonists|inverse agonist|inverse agonists)/ig);
              my $count_matches_syn2 = @count_matches_syn2;
              for ( my $i = 1; $i < $count_matches_syn2 + 1; $i++ ) {
                my $append;
                if ($1 ne '') {
                  if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                    $append = 'receptor';
                  } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                    $append = 'kinase';
                  }
                  push @title_matches, "TITLE EXACT 20: " .$syn . " $append";
                } else {
                  push @title_matches, "TITLE EXACT 20: " .$syn;
                }
                $found = $found + $count_matches_syn2;
              }
            }
            if ($found == $count_matches) {
              last;
            }
          }
          if ($found <$count_matches) {
            my @matches = $title_text =~/((?:\S+)(?:\s*receptor|\s*kinase|\s*receptors|\s*kinases)?)\s*(?:\bagonist|\bagonists|partial agonist|partial agonists|inverse agonist|inverse agonists)/ig;
            foreach my $m (@matches) {
              if (length($m)>2 and lc($m) ne 'the' and !grep(/^EXACT 20: \Q$m\E$/i, @title_matches)) {push @title_matches, "TITLE FREE 20: " . $m;};
            }
            $found = 0;
          }
        }
        $found=0; undef %start_or_end;
        $title_text = $title->to_literal();
        if ($title_text =~/.+? selective binding compounds/i) {
          my @count_matches = ($title_text =~/.+? selective binding compounds/ig); 
          my $count_matches = @count_matches;
          foreach my $syn (sort { length($b) <=> length($a) } keys %title_matches) {
            if (($title_text =~/\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*selective binding compounds/i) and $start_or_end{$+[0]}==0){
              $start_or_end{$+[0]} = 1;
              my @count_matches_syn2 = ($title_text =~/\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*selective binding compounds/ig);
              my $count_matches_syn2 = @count_matches_syn2;
              for ( my $i = 1; $i < $count_matches_syn2 + 1; $i++ ) {
                my $append;
                if ($1 ne '') {
                  if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                    $append = 'receptor';
                  } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                    $append = 'kinase';
                  }
                  push @title_matches, "TITLE EXACT 21: " .$syn . " $append";
                } else {
                  push @title_matches, "TITLE EXACT 21: " .$syn;
                }
                $found = $found + $count_matches_syn2;
              }
            }
            if ($found == $count_matches) {
              last;
            }
          }
          if ($found <$count_matches) {
            my @matches = $title_text =~/(?:((?:\S+)(?:\s*receptor|\s*kinase|\s*receptors|\s*kinases)?)\s*selective binding compounds)/ig;
            foreach my $m (@matches) {
              if (length($m)>2 and lc($m) ne 'the' and !grep(/^EXACT 21: \Q$m\E$/i, @title_matches)) {push @title_matches, "TITLE FREE 21: " . $m;};
            }
            $found = 0;
          }
        }
        $found=0; undef %start_or_end;
        $title_text = $title->to_literal();
        if ($title_text =~/activity of .+?/i) {
          my @count_matches = ($title_text =~/activity of .+?/ig);
          my $count_matches = @count_matches; 
          foreach my $syn (sort { length($b) <=> length($a) } keys %title_matches) {
            if (($title_text =~/activity of\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/i) and $start_or_end{$-[0]}==0) {
              $start_or_end{$+[0]} = 1;
              my @count_matches_syn2 = ($title_text =~/activity of\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig);
              my $count_matches_syn2 = @count_matches_syn2;
              for ( my $i = 1; $i < $count_matches_syn2 + 1; $i++ ) {
                my $append;
                if ($1 ne '') {
                  if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                    $append = 'receptor';
                  } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                    $append = 'kinase';
                  }
                  push @title_matches, "TITLE EXACT 24: " .$syn . " $append";
                } else {
                  push @title_matches, "TITLE EXACT 24: " .$syn;
                }
                $found = $found + $count_matches_syn2;
              }
            }
            if ($found == $count_matches) {
              last;
            }
          }
          if ($found <$count_matches) {
            my @matches = $title_text =~/activity of\s*((?:\S+)(?:\s*receptor|\s*kinase|\s*receptors|\s*kinases)?)/ig;
            foreach my $m (@matches) {
              if (length($m)>2 and lc($m) ne 'the' and !grep(/^EXACT 24: \Q$m\E$/i, @title_matches)) {push @title_matches, "TITLE FREE 24: " . $m;};
            } 
            $found =0;
          }
        }
        $found=0; undef %start_or_end;
        $title_text = $title->to_literal();
        if ($title_text =~/.+? antibodies/i) {
          my @count_matches = ($title_text =~/(?:anti-)?\s*.+?\s*(?:specific)?\s*(?:monoclonal)?\s*\bantibodies/ig); 
          my $count_matches = @count_matches;
          foreach my $syn (sort { length($b) <=> length($a) } keys %title_matches) {
            if (($title_text =~/(?:anti-)?\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*(specific)?\s*(?:monoclonal antibodies|antibodies)/i) and $start_or_end{$+[0]}==0){
              $start_or_end{$+[0]} = 1;
              my @count_matches_syn2 = ($title_text =~/(?:anti-)?\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*(?:specific)?\s*(?:monoclonal antibodies|antibodies)/ig);
              my $count_matches_syn2 = @count_matches_syn2;
              for ( my $i = 1; $i < $count_matches_syn2 + 1; $i++ ) {
                my $append;
                if ($1 ne '') {
                  if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                    $append = 'receptor';
                  } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                    $append = 'kinase';
                  }
                  push @title_matches, "TITLE EXACT 25: " .$syn . " $append";
                } else {
                  push @title_matches, "TITLE EXACT 25: " .$syn;
                }
                $found = $found + $count_matches_syn2;
              }
            }
            if ($found == $count_matches) {
              last;
            }
          }
          if ($found <$count_matches) {
            my @matches = $title_text =~/(?:anti-)?\s*((?:\S+)(?:\s*receptor|\s*kinase|\s*receptors|\s*kinases)?)\s*(?:specific)?\s*(?:monoclonal antibodies|antibodies)/ig;
            foreach my $m (@matches) {
              if (length($m)>2 and lc($m) ne 'the' and !grep(/^EXACT 25: \Q$m\E$/i, @title_matches) and lc($m)!~/anti-/) {push @title_matches, "TITLE FREE 25: " . $m;};
            }
            $found = 0;
          }
        }
        $found=0; undef %start_or_end;
        $title_text = $title->to_literal();
        if ($title_text =~/.+? activity/i) {
          my @count_matches = ($title_text =~/.+?\s*(?:\binhibitory|inhibiting)?\s*\bactivity/ig); 
          my $count_matches = @count_matches;
          foreach my $syn (sort { length($b) <=> length($a) } keys %title_matches) {
            if (($title_text =~/\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*(?:inhibitory|inhibiting|antagonistic)?\s*\bactivity/i) and $start_or_end{$+[0]}==0){
              $start_or_end{$+[0]} = 1;
              my @count_matches_syn2 = ($title_text =~/\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*(?:inhibitory|inhibiting|antagonistic)?\s*\bactivity/ig);
              my $count_matches_syn2 = @count_matches_syn2;
              for ( my $i = 1; $i < $count_matches_syn2 + 1; $i++ ) {
                my $append;
                if ($1 ne '') {
                  if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                    $append = 'receptor';
                  } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                    $append = 'kinase';
                  }
                  push @title_matches, "TITLE EXACT 26: " .$syn . " $append";
                } else {
                  push @title_matches, "TITLE EXACT 26: " .$syn;
                }
                $found = $found + $count_matches_syn2;
              }
            }
            if ($found == $count_matches) {
              last; 
            }
          }
          if ($found <$count_matches) {
            my @matches = $title_text =~/(\S+(?:\s*receptor|\s*kinase|\s*receptors|\s*kinases)?)\s*(?:inhibitory|inhibiting|antagonistic)?\s*\bactivity/ig;
            foreach my $m (@matches) {
              if (length($m)>2 and lc($m) ne 'the' and !grep(/^EXACT 26: \Q$m\E$/i, @title_matches)) {push @title_matches, "TITLE FREE 26: " . $m;};
            }
            $found = 0;
          }
        }
        $found=0; undef %start_or_end;
        $title_text = $title->to_literal();
        if ($title_text =~/inhibitor of .+?/i) {
          my @count_matches = ($title_text =~/inhibitor of .+?/ig);
          my $count_matches = @count_matches;
          foreach my $syn (sort { length($b) <=> length($a) } keys %title_matches) {
            if (($title_text =~/inhibitor of\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/i) and $start_or_end{$-[0]}==0){
              $start_or_end{$+[0]} = 1;
              my @count_matches_syn2 = ($title_text =~/inhibitor of \b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig);
              my $count_matches_syn2 = @count_matches_syn2;
              for ( my $i = 1; $i < $count_matches_syn2 + 1; $i++ ) {
                my $append;
                if ($1 ne '') {
                  if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                    $append = 'receptor';
                  } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                    $append = 'kinase';
                  }
                  push @title_matches, "TITLE EXACT 27: " .$syn . " $append";
                } else {
                  push @title_matches, "TITLE EXACT 27: " .$syn;
                }
                $found = $found + $count_matches_syn2;
              }
            }
            if ($found == $count_matches) {
              last;
            }
          }
          if ($found <$count_matches) {
            my @matches = $title_text =~/inhibitor of\s*(?:(\S+)(\s*receptor|\s*kinase|\s*receptors|\s*kinases)?)/ig;
            foreach my $m (@matches) {
              if (length($m)>2 and lc($m) ne 'the' and !grep(/^EXACT 27: \Q$m\E$/i, @title_matches)) {push @title_matches, "TITLE FREE 27: " . $m;};
            }
            $found = 0;
          }
        }
        $found=0; undef %start_or_end;
        $title_text = $title->to_literal();
        if ($title_text =~/.+? binding/i) {
          my @count_matches = ($title_text =~/.+? binding/ig); 
          my $count_matches = @count_matches;
          foreach my $syn (sort { length($b) <=> length($a) } keys %title_matches) {
            if (($title_text =~/\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*binding/i) and $start_or_end{$+[0]}==0){
              $start_or_end{$+[0]} = 1;
              my @count_matches_syn2 = ($title_text =~/\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*binding/ig);
              my $count_matches_syn2 = @count_matches_syn2;
              for ( my $i = 1; $i < $count_matches_syn2 + 1; $i++ ) {
                my $append;
                if ($1 ne '') {
                  if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                    $append = 'receptor';
                  } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                    $append = 'kinase';
                  }
                  push @title_matches, "TITLE EXACT 29: " .$syn . " $append";
                } else {
                  push @title_matches, "TITLE EXACT 29: " .$syn;
                }
                $found = $found + $count_matches_syn2;
              }
            }
            if ($found == $count_matches) {
              last;
            }
          }
          if ($found <$count_matches) {
            my @matches = $title_text =~/((?:\S+)(?:\s*receptor|\s*kinase|\s*receptors|\s*kinases)?)\s*binding/ig;
            foreach my $m (@matches) {
              if (length($m)>2 and lc($m) ne 'the' and !grep(/^EXACT 29: \Q$m\E$/i, @title_matches)) {push @title_matches, "TITLE FREE 29: " . $m;};
            }
            $found = 0;
          }
        }
        $found=0; undef %start_or_end;
        $title_text = $title->to_literal();
        if ($title_text =~/antibodies directed against .+?/i) {
          my @count_matches = ($title_text =~/antibodies directed against .+?/ig); 
          my $count_matches = @count_matches;
          foreach my $syn (sort { length($b) <=> length($a) } keys %title_matches) {
            if (($title_text =~/(?:monoclonal antibodies|antibodies)\s*directed against\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/i) and $start_or_end{$-[0]}==0){
              $start_or_end{$+[0]} = 1;
              my @count_matches_syn2 = ($title_text =~/(?:monoclonal antibodies|antibodies)\s*directed against\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig);
              my $count_matches_syn2 = @count_matches_syn2;
              for ( my $i = 1; $i < $count_matches_syn2 + 1; $i++ ) {
                my $append;
                if ($1 ne '') {
                  if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                    $append = 'receptor';
                  } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                    $append = 'kinase';
                  }
                  push @title_matches, "TITLE EXACT 30: " .$syn . " $append";
                } else {
                  push @title_matches, "TITLE EXACT 30: " .$syn;
                }
                $found = $found + $count_matches_syn2;
              }
            }
            if ($found == $count_matches) {
              last;
            }
          }
          if ($found <$count_matches) {
            my @matches = $title_text =~/(?:monoclonal antibodies|antibodies)\s*directed against\s*((?:\b(\S+)\b)(?:\s*receptor|\s*kinase|\s*receptors|\s*kinases)?)/ig;
            foreach my $m (@matches) {
              if (length($m)>2 and lc($m) ne 'the' and !grep(/^EXACT 30: \Q$m\E$/i, @title_matches)) {push @title_matches, "TITLE FREE 30: " . $m;};
            }
            $found = 0;
          }
        }
        $found=0; undef %start_or_end;
        $title_text = $title->to_literal();
        if ($title_text =~/treatment of .+? related/i) {
          my @count_matches = ($title_text =~/treatment of .+? related/ig); 
          my $count_matches = @count_matches;
          foreach my $syn (sort { length($b) <=> length($a) } keys %title_matches) {
            if ($title_text =~/treatment of\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*related/i) {
              my @count_matches_syn2 = ($title_text =~/treatment of\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*related/ig);
              my $count_matches_syn2 = @count_matches_syn2;
              for ( my $i = 1; $i < $count_matches_syn2 + 1; $i++ ) {
                my $append;
                if ($1 ne '') {
                  if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                    $append = 'receptor';
                  } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                    $append = 'kinase';
                  }
                  push @title_matches, "TITLE EXACT 31: " .$syn . " $append";
                } else {
                  push @title_matches, "TITLE EXACT 31: " .$syn;
                }
                $found = $found + $count_matches_syn2;
              }
            }
            if ($found == $count_matches) {
              last;
            }
          }
          if ($found <$count_matches) {
            my @matches = $title_text =~/treatment of\s*((?:\S+)(?:\s*receptor|\s*kinase|\s*receptors|\s*kinases)?)\s*related/ig;
            foreach my $m (@matches) {
              if (length($m)>2 and lc($m) ne 'the' and !grep(/^EXACT 31: \Q$m\E$/i, @title_matches)) {push @title_matches, "TITLE FREE 31: " . $m;};
            }
            $found = 0;
          }
        }
        $found=0; undef %start_or_end;
        $title_text = $title->to_literal();
        if ($title_text =~/antibody for .+?/i) {
          my @count_matches = ($title_text =~/antibody for .+?/ig); 
          my $count_matches = @count_matches;
          foreach my $syn (sort { length($b) <=> length($a) } keys %title_matches) {
            if (($title_text =~/(?:monoclonal antibody|antibody)\s*for\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/i) and $start_or_end{$-[0]}==0) {
              $start_or_end{$+[0]} = 1;
              my @count_matches_syn2 = ($title_text =~/(?:monoclonal antibody|antibody)\s*for\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig);
              my $count_matches_syn2 = @count_matches_syn2;
              for ( my $i = 1; $i < $count_matches_syn2 + 1; $i++ ) {
                my $append;
                if ($1 ne '') {
                  if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                    $append = 'receptor';
                  } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                    $append = 'kinase';
                  }
                  push @title_matches, "TITLE EXACT 32: " .$syn . " $append";
                } else {
                  push @title_matches, "TITLE EXACT 32: " .$syn;
                }
                $found = $found + $count_matches_syn2;
              }
            }
            if ($found == $count_matches) {
              last;
            }
          }
          if ($found <$count_matches) {
            my @matches = $title_text =~/(?:monoclonal antibody|antibody)\s*for\s*(\S+(?:\s*receptor|\s*kinase|\s*receptors|\s*kinases)?)/ig;
            foreach my $m (@matches) {
              if (length($m)>2 and lc($m) ne 'the' and !grep(/^EXACT 32: \Q$m\E$/i, @title_matches)) {push @title_matches, "TITLE FREE 32: " . $m;};
            }
            $found = 0;
          }
        }
        $found=0; undef %start_or_end;
        $title_text = $title->to_literal();
        if ($title_text =~/anti-.+?\s*(?:monoclonal)?\s*antibody/i) {
          my @count_matches = ($title_text =~/anti-.+?\s*(?:monoclonal)?\s*antibody/ig);
          my $count_matches = @count_matches;
          foreach my $syn (sort { length($b) <=> length($a) } keys %title_matches) {
            if ($title_text =~/anti-\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*(?:monoclonal antibody|antibody)/i) {
              my @count_matches_syn2 = ($title_text =~/anti-\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*(?:monoclonal antibody|antibody)/ig);
              my $count_matches_syn2 = @count_matches_syn2;
              for ( my $i = 1; $i < $count_matches_syn2 + 1; $i++ ) {
                my $append;
                if ($1 ne '') {
                  if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                    $append = 'receptor';
                  } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                    $append = 'kinase';
                  }
                  push @title_matches, "TITLE EXACT 33: " .$syn . " $append";
                } else {
                  push @title_matches, "TITLE EXACT 33: " .$syn;
                }
                $found = $found + $count_matches_syn2;
              }
            }
            if ($found == $count_matches) {
              last;
            }
          }
          if ($found <$count_matches) {
            my @matches = $title_text =~/anti-((?:\S+)(?:\s*receptor|\s*kinase|\s*receptors|\s*kinases)?)\s*(?:monoclonal antibody|antibody)/ig;
            foreach my $m (@matches) {
              if (length($m)>2 and lc($m) ne 'the' and !grep(/^EXACT 33: \Q$m\E$/i, @title_matches)) {push @title_matches, "TITLE FREE 33: " . $m;};
            }
            $found = 0;
          }
        }
        $found=0; undef %start_or_end;
        $title_text = $title->to_literal();
        if ($title_text =~/human anti-.+?/i)  {
          my @count_matches = ($title_text =~/human anti-.+?/ig);
          my $count_matches = @count_matches;
          foreach my $syn (sort { length($b) <=> length($a) } keys %title_matches) {
            if (($title_text =~/human anti-\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/i) and $start_or_end{$-[0]}==0) {
              $start_or_end{$+[0]} = 1;
              my @count_matches_syn2 = ($title_text =~/human anti-\Q$syn\E\b/ig);
              my $count_matches_syn2 = @count_matches_syn2;
              for ( my $i = 1; $i < $count_matches_syn2 + 1; $i++ ) {
                my $append;
                if ($1 ne '') {
                  if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                    $append = 'receptor';
                  } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                    $append = 'kinase';
                  }
                  push @title_matches, "TITLE EXACT 34: " .$syn . " $append";
                } else {
                  push @title_matches, "TITLE EXACT 34: " .$syn;
                }
                $found = $found + $count_matches_syn2;
              }
            }
            if ($found == $count_matches) {
              last;
            }
          }
          if ($found <$count_matches) {
            my @matches = $title_text =~/human anti-((?:\S+)(?:\s*receptor|\s*kinase|\s*receptors|\s*kinases)?)/ig;
            foreach my $m (@matches) {
              if (length($m)>2 and lc($m) ne 'the' and !grep(/^EXACT 34: \Q$m\E$/i, @title_matches)) {push @title_matches, "TITLE FREE 34: " . $m;};
            }
            $found = 0;
          }
        }
        $found=0; undef %start_or_end;
        $title_text = $title->to_literal();
        if ($title_text=~/antibodies to .+?/i) {
          my @count_matches = ($title_text=~/antibodies to .+?/ig); 
          my $count_matches = @count_matches;
          foreach my $syn (sort { length($b) <=> length($a) } keys %title_matches) {
            if (($title_text =~/(?:monoclonal antibodies to|antibodies to)\s*(?:human)?\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/i) and $start_or_end{$-[0]}==0){
              $start_or_end{$+[0]} = 1;
              my @count_matches_syn2 = ($title_text =~/(?:monoclonal antibodies to|antibodies to)\s*(?:human)?\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig);
              my $count_matches_syn2 = @count_matches_syn2;
              for ( my $i = 1; $i < $count_matches_syn2 + 1; $i++ ) {
                my $append;
                if ($1 ne '') {
                  if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                    $append = 'receptor';
                  } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                  $append = 'kinase';
                  }
                  push @title_matches, "TITLE EXACT 35: " .$syn . " $append";
                } else {
                  push @title_matches, "TITLE EXACT 35: " .$syn;
                }
                $found = $found + $count_matches_syn2;
              }
            }
            if ($found == $count_matches) {
              last;
            }
          }
          if ($found <$count_matches) {
            my @matches = $title_text =~/(?:(?:monoclonal antibodies to|antibodies to)\s*(?:human)?\s*((?:\S+)(?:\s*receptor|\s*kinase|\s*receptors|\s*kinases)?))/ig;
            foreach my $m (@matches) {
              if (length($m)>2 and lc($m) ne 'the' and !grep(/^EXACT 35: \Q$m\E$/i, @title_matches)) {push @title_matches, "TITLE FREE 35: " . $m;};
            }
            $found = 0;
          }
        }
        $found=0; undef %start_or_end;
        $title_text = $title->to_literal();
        if ($title_text =~/high .+? affinity/i) {
          my @count_matches = ($title_text =~/high .+? affinity/ig); 
          my $count_matches = @count_matches;
          foreach my $syn (sort { length($b) <=> length($a) } keys %title_matches) {
            if ($title_text =~/high\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*affinity/i) {
              my @count_matches_syn2 = ($title_text =~/high\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*affinity/ig);
              my $count_matches_syn2 = @count_matches_syn2;
              for ( my $i = 1; $i < $count_matches_syn2 + 1; $i++ ) {
                my $append;
                if ($1 ne '') {
                  if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                    $append = 'receptor';
                  } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                    $append = 'kinase';
                  }
                  push @title_matches, "TITLE EXACT 36: " .$syn . " $append";
                } else {
                  push @title_matches, "TITLE EXACT 36: " .$syn;
                }
                $found = $found + $count_matches_syn2;
              }
            }
            if ($found == $count_matches) {
              last;
            }
          }
          if ($found <$count_matches) {
            my @matches = $title_text =~/(?:high\s*((?:\S+)(?:\s*receptor|\s*kinase|\s*receptors|\s*kinases)?)\s*affinity)/ig;
            foreach my $m (@matches) {
              if (length($m)>2 and lc($m) ne 'the' and !grep(/^EXACT 36: \Q$m\E$/i, @title_matches)) {push @title_matches, "TITLE FREE 36: " . $m;};
            }
            $found = 0;
          }
        }
        $found=0; undef %start_or_end;
        $title_text = $title->to_literal();
        if ($title_text =~/inhibiting .+?/i) {
          my @count_matches = ($title_text =~/inhibiting .+?/ig); 
          my $count_matches = @count_matches;
          foreach my $syn (sort { length($b) <=> length($a) } keys %title_matches) {
            if (($title_text =~/inhibiting\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/i) and $start_or_end{$-[0]}==0) {
              $start_or_end{$+[0]} = 1;
              my @count_matches_syn2 = ($title_text =~/inhibiting\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig);
              my $count_matches_syn2 = @count_matches_syn2;
              for ( my $i = 1; $i < $count_matches_syn2 + 1; $i++ ) {
                my $append;
                if ($1 ne '') {
                  if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                    $append = 'receptor';
                  } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                    $append = 'kinase';
                  }
                  push @title_matches, "TITLE EXACT 39: " .$syn . " $append";
                } else {
                  push @title_matches, "TITLE EXACT 39: " .$syn;
                }
                $found = $found + $count_matches_syn2;
              }
            }
            if ($found == $count_matches) {
              last;
            }
          }
          if ($found <$count_matches) {
            my @matches = $title_text =~/inhibiting\s*((?:\S+)(?:\s*receptor|\s*kinase|\s*receptors|\s*kinases)?)/ig;
            foreach my $m (@matches) {
              if (length($m)>2 and lc($m) ne 'the' and !grep(/^EXACT 39: \Q$m\E$/i, @title_matches)) {push @title_matches, "TITLE FREE 39: " . $m;};
            }
            $found = 0;
          }
        }
        $found=0; undef %start_or_end;
        $title_text = $title->to_literal();
        if ($title_text =~/blocks|block .+/i) {
          my @count_matches = ($title_text =~/(blocks|block)\b(?:the)?\b.+?/ig);
          my $count_matches = @count_matches;
          foreach my $syn (sort { length($b) <=> length($a) } keys %title_matches) {
            if (($title_text =~/(?:blocks\b|block\b)\s*(?:the)?\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/i) and $start_or_end{$-[0]}==0) {
              $start_or_end{$+[0]} = 1;
              my @count_matches_syn2 = ($title_text =~/(?:blocks\b|block\b)\s*(?:the)?\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig);
              my $count_matches_syn2 = @count_matches_syn2;
              for ( my $i = 1; $i < $count_matches_syn2 + 1; $i++ ) {
                my $append;
                if ($1 ne '') {
                  if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                    $append = 'receptor';
                  } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                    $append = 'kinase';
                  }
                  push @title_matches, "TITLE EXACT 40: " .$syn . " $append";
                } else {
                  push @title_matches, "TITLE EXACT 40: " .$syn;
                }
                $found = $found + $count_matches_syn2;
              }
            }
            if ($found == $count_matches) {
              last;
            }
          }
          if ($found <$count_matches) {
            my @matches = $title_text =~/(?:blocks\b|block\b)\s*(?:the)?\s*((?:\S+)(?:\s*receptor|\s*kinase|\s*receptors|\s*kinases)?)/ig;
            foreach my $m (@matches) {
              if (length($m)>2 and lc($m) ne 'the' and !grep(/^EXACT 40: \Q$m\E$/i, @title_matches)) {push @title_matches, "TITLE FREE 40: " . $m;};
            }
            $found = 0;
          }
        }
        $found=0; undef %start_or_end;
        $title_text = $title->to_literal();
        if ($title_text =~/blocking .+/i) {
          my @count_matches = ($title_text =~/blocking\b\s*(?:the\b|a\b|an\b)?\s*.+?/ig);
          my $count_matches = @count_matches;
          foreach my $syn (sort { length($b) <=> length($a) } keys %title_matches) {
            if (($title_text =~/blocking\b\s*(?:the\b|a\b|an\b)?\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/i) and $start_or_end{$-[0]}==0) {
              $start_or_end{$+[0]} = 1;
              my @count_matches_syn2 = ($title_text =~/blocking\b\s*(?:the\b|a\b|an\b)?\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig);
              my $count_matches_syn2 = @count_matches_syn2;
              for ( my $i = 1; $i < $count_matches_syn2 + 1; $i++ ) {
                my $append;
                if ($1 ne '') {
                  if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                    $append = 'receptor';
                  } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                    $append = 'kinase';
                  }
                  push @title_matches, "TITLE EXACT 41: " .$syn . " $append";
                } else {
                  push @title_matches, "TITLE EXACT 41: " .$syn;
                }
                $found = $found + $count_matches_syn2;
              }
            }
            if ($found == $count_matches) {
              last;
            }
          }
          if ($found <$count_matches) {
            my @matches = $title_text =~/blocking\b\s*(?:the\b|a\b|an\b)?\s*((?:\S+)(?:\s*receptor|\s*kinase|\s*receptors|\s*kinases)?)/ig;
            foreach my $m (@matches) {
              if (length($m)>2 and lc($m) ne 'the' and !grep(/^EXACT 41: \Q$m\E$/i, @title_matches)) {push @title_matches, "TITLE FREE 41: " . $m;};
            }
            $found = 0;
          }
        }
        $found=0; undef %start_or_end;
        $title_text = $title->to_literal();
        if ($title_text =~/ligand|ligands for .+/i) {
          my @count_matches = ($title_text =~/(?:ligand|ligands)\s*(?:for the|for)\b.+?/ig);
          my $count_matches = @count_matches;
          foreach my $syn (sort { length($b) <=> length($a) } keys %title_matches) {
            if (($title_text =~/(?:ligand|ligands)\s*(?:for the\b|for\b)\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/i) and $start_or_end{$-[0]}==0) {
              $start_or_end{$+[0]} = 1;
              my @count_matches_syn2 = ($title_text =~/(?:ligand|ligands)\s*(?:for the\b|for\b)\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig);
              my $count_matches_syn2 = @count_matches_syn2;
              for ( my $i = 1; $i < $count_matches_syn2 + 1; $i++ ) {
                my $append;
                if ($1 ne '') {
                  if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                    $append = 'receptor';
                  } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                    $append = 'kinase';
                  }
                  push @title_matches, "TITLE EXACT 42: " .$syn . " $append";
                } else {
                  push @title_matches, "TITLE EXACT 42: " .$syn;
                }
                $found = $found + $count_matches_syn2;
              }
            }
            if ($found == $count_matches) {
              last;
            }
          }
          if ($found <$count_matches) {
            my @matches = $title_text =~/(?:ligand\b|ligands\b)\s*(?:for the\b|for\b)\s*((?:\S+)(?:\s*receptor|\s*kinase|\s*receptors|\s*kinases)?)/ig;
            foreach my $m (@matches) {
              if (length($m)>2 and lc($m) ne 'the' and !grep(/^EXACT 42: \Q$m\E$/i, @title_matches)) {push @title_matches, "TITLE FREE 42: " . $m;};
            }
            $found = 0;
          }
        }
        $found=0; undef %start_or_end;
        $title_text = $title->to_literal();
        if ($title_text =~/compounds that interact with .+/i) {
          my @count_matches = ($title_text =~/compounds that interact with (?:the\b)?.+?/ig);
          my $count_matches = @count_matches;
          foreach my $syn (sort { length($b) <=> length($a) } keys %title_matches) {
            if (($title_text =~/compounds that interact with (?:the\b)?\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/i) and $start_or_end{$-[0]}==0) {
              $start_or_end{$+[0]} = 1;
              my @count_matches_syn2 = ($title_text =~/compounds that interact with (?:the\b)?\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig);
              my $count_matches_syn2 = @count_matches_syn2;
              for ( my $i = 1; $i < $count_matches_syn2 + 1; $i++ ) {
                my $append;
                if ($1 ne '') {
                  if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                    $append = 'receptor';
                  } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                    $append = 'kinase';
                  }
                  push @title_matches, "TITLE EXACT 43: " .$syn . " $append";
                } else {
                  push @title_matches, "TITLE EXACT 43: " .$syn;
                }
                $found = $found + $count_matches_syn2;
              }
            }
            if ($found == $count_matches) {
              last;
            }
          }
          if ($found <$count_matches) {
            my @matches = $title_text =~/compounds that interact with (?:the\b)?\s*((?:\S+)(?:\s*receptor|\s*kinase|\s*receptors|\s*kinases)?)/ig;
            foreach my $m (@matches) {
              if (length($m)>2 and lc($m) ne 'the' and !grep(/^EXACT 43: \Q$m\E$/i, @title_matches)) {push @title_matches, "TITLE FREE 43: " . $m;};
            }
            $found = 0;
          }
        }
        $found=0; undef %start_or_end;
        $title_text = $title->to_literal();
        if ($title_text =~/modulating the function of .+/i) {
          my @count_matches = ($title_text =~/modulating the function of (?:a\b|an\b|the\b)?.+?/ig);
          my $count_matches = @count_matches;
          foreach my $syn (sort { length($b) <=> length($a) } keys %title_matches) {
            if (($title_text =~/modulating the function of\s*(?:a\b|an\b|the\b)?\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/i) and $start_or_end{$-[0]}==0) {
              $start_or_end{$+[0]} = 1;
              my @count_matches_syn2 = ($title_text =~/modulating the function of\s*(?:a\b|an\b|the\b)?\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig);
              my $count_matches_syn2 = @count_matches_syn2;
              for ( my $i = 1; $i < $count_matches_syn2 + 1; $i++ ) {
                my $append;
                if ($1 ne '') {
                  if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                    $append = 'receptor';
                  } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                    $append = 'kinase';
                  }
                  push @title_matches, "TITLE EXACT 44: " .$syn . " $append";
                } else {
                  push @title_matches, "TITLE EXACT 44: " .$syn;
                }
                $found = $found + $count_matches_syn2;
              }
            }
            if ($found == $count_matches) {
              last;
            }
          } 
          if ($found <$count_matches) {
            my @matches = $title_text =~/modulating the function of\s*(?:a\b|an\b|the\b)?\s*((?:\S+)(?:\s*receptor|\s*kinase|\s*receptors|\s*kinases)?)/ig;
            foreach my $m (@matches) {
              if (length($m)>2 and lc($m) ne 'the' and !grep(/^EXACT 44: \Q$m\E$/i, @title_matches)) {push @title_matches, "TITLE FREE 44: " . $m;};
            }
            $found = 0;
          }
        }
        $found=0; undef %start_or_end;
        $title_text = $title->to_literal();
        if ($title_text =~/.+? ligand\b|ligands\b/i) {
          my @count_matches = ($title_text =~/.+? ligand|ligands\b/ig);
          my $count_matches = @count_matches;
          foreach my $syn (sort { length($b) <=> length($a) } keys %title_matches) {
            if (($title_text =~/\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*(?:ligand\b|ligands)\b/i) and $start_or_end{$+[0]}==0) {
              $start_or_end{$+[0]} = 1;
              my @count_matches_syn2 = ($title_text =~/\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*(?:ligand\b|ligands\b)/ig);
              my $count_matches_syn2 = @count_matches_syn2;
              for ( my $i = 1; $i < $count_matches_syn2 + 1; $i++ ) {
                my $append;
                if ($1 ne '') {
                  if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                    $append = 'receptor';
                  } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                    $append = 'kinase';
                  }
                  push @title_matches, "TITLE EXACT 45: " .$syn . " $append";
                } else {
                  push @title_matches, "TITLE EXACT 45: " .$syn;
                }
                $found = $found + $count_matches_syn2;
              }
            }
            if ($found == $count_matches) {
              last;
            }
          }
          if ($found <$count_matches) {
            my @matches = $title_text =~/((?:\S+)(?:\s*receptor|\s*kinase|\s*receptors|\s*kinases)?)\s*ligand\b|ligands\b/ig;
            foreach my $m (@matches) {
              if (length($m)>2 and lc($m) ne 'the' and !grep(/^EXACT 45: \Q$m\E$/i, @title_matches)) {push @title_matches, "TITLE FREE 45: " . $m;};
            }
            $found = 0;
          }
        }
      }
    $found = 0;
    my $match_abstract;
    my @matches_positions;
    my @pos;
      foreach my $abstract ($npat->findnodes('//abstract[@lang="EN"]')) {
        $found=0; undef %start_or_end;
        $abstract_text = $abstract->to_literal();
        foreach my $syn (sort { length($b) <=> length($a) } keys %syns) {
          $match_abstract = 0;
          @matches_positions =();
          while ($abstract_text =~/\b\Q$syn\E\b/ig) {
            my $start = $-[0];
            my $end = $+[0];
            push @matches_positions, {'syn'=>lc($syn), 'start'=>$start, 'end'=>$end, 'discard'=>0};
            if (scalar (keys %abstract_matches ==0)) {
              $abstract_matches{lc($syn)} = 1;
              push @pos, {'syn'=>lc($syn), 'start'=>$start, 'end'=>$end};
            } else {
              OUTER: foreach my $p (@pos) {
                foreach my $mp (@matches_positions) {
                if (($p->{end} >= $mp->{end} and $p->{start} < $mp->{start}) or ($p->{start} <= $mp->{start} and $p->{end} > $mp->{end})) {
                  splice @matches_positions;
                }
    
                }
              }
              foreach my $mp2 (@matches_positions) {
                if ($mp2->{discard}==0) {
                  push @pos, {'syn'=>lc($syn), 'start'=>$-[0], 'end'=>$+[0]}; 
                  $abstract_matches{lc($syn)} = 1;
                }
              }
            }
          }
        }
        if ($abstract_text =~/.+? inhibitors/i) {
          my @count_matches = ($abstract_text =~/.+? inhibitors/ig); 
          my $count_matches = @count_matches;
          foreach my $syn (sort { length($b) <=> length($a) } keys %abstract_matches) {
            if (($abstract_text =~/\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*inhibitors/i) and $start_or_end{$+[0]}==0) {
              $start_or_end{$+[0]} = 1;
              my @count_matches_syn2 = ($abstract_text =~/\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*inhibitors/ig);
              my $count_matches_syn2 = @count_matches_syn2;
              for ( my $i = 1; $i < $count_matches_syn2 + 1; $i++ ) {
                my $append;
                if ($1 ne '') {
                  if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                    $append = 'receptor';
                  } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                    $append = 'kinase';
                  }
                  push @abstract_matches, "ABSTRACT EXACT 1: " .$syn . " $append";
                } else {
                  push @abstract_matches, "ABSTRACT EXACT 1: " .$syn;
                }
                $found = $found + $count_matches_syn2;
              }
            }
            if ($found == $count_matches) {
              last;
            }
          }
          if ($found <$count_matches) {
            my @matches = $abstract_text =~/(?:((?:\S+)(?:\s*receptor|\s*kinase|\s*receptors|\s*kinases)?))\s*inhibitors\b/ig;
            foreach my $m (@matches) {
              if (length($m)>2 and lc($m) ne 'the' and !grep(/^EXACT 1: \Q$m\E$/i, @abstract_matches)) {push @abstract_matches, "ABSTRACT FREE 1: " . $m;};
            }
            $found = 0;
          }
        }
        $found=0; undef %start_or_end;
        $abstract_text = $abstract->to_literal();
          if ($abstract_text =~/inhibitors of .+/i) {
          my @count_matches = ($abstract_text=~/inhibitors of\s*(?:soluble|the human|human)?\b.+?/ig); 
          my $count_matches = @count_matches;
          foreach my $syn (sort { length($b) <=> length($a) } keys %abstract_matches) {
            if (($abstract_text =~/inhibitors of\s*(?:soluble|the human|human)?\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/i) and $start_or_end{$-[0]}==0) {
              $start_or_end{$+[0]} = 1;
              my @count_matches_syn2 = ($abstract_text =~/inhibitors of\s*(?:soluble|the human|human)?\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig);
              my $count_matches_syn2 = @count_matches_syn2;
              for ( my $i = 1; $i < $count_matches_syn2 + 1; $i++ ) {
                my $append;
                if ($1 ne '') {
                  if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                    $append = 'receptor';
                  } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                    $append = 'kinase';
                  }
                  push @abstract_matches, "ABSTRACT EXACT 3: " .$syn . " $append";
                } else {
                  push @abstract_matches, "ABSTRACT EXACT 3: " .$syn;
                }
                $found = $found + $count_matches_syn2;
              }
            }
            if ($found == $count_matches) {
              last;
            }
          }
          if ($found <$count_matches) {
            my @matches = $abstract_text =~/inhibitors of\s*(?:soluble|the human|human)?\s*((?:\S+)(?:\s*receptor|\s*kinase|\s*receptors|\s*kinases)?)/ig;
            foreach my $m (@matches) {
              if (length($m)>2 and lc($m) ne 'the' and !grep(/^EXACT 3: \Q$m\E$/i, @abstract_matches)) {push @abstract_matches, "ABSTRACT FREE 3: " . $m;};
            }
            $found = 0;
          }
        }
        $found=0; undef %start_or_end;
        $abstract_text = $abstract->to_literal();
        if ($abstract_text =~/.+? inhibitor\b/i) {
          my @count_matches = ($abstract_text =~/.+? inhibitor\b/ig); 
          my $count_matches = @count_matches;
          foreach my $syn (sort { length($b) <=> length($a) } keys %abstract_matches) {
            if (($abstract_text =~/\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*inhibitor\b/i) and $start_or_end{$+[0]}==0) {
              $start_or_end{$+[0]} = 1;
              my @count_matches_syn2 = ($abstract_text =~/\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*inhibitor\b/ig);
              my $count_matches_syn2 = @count_matches_syn2;
              for ( my $i = 1; $i < $count_matches_syn2 + 1; $i++ ) {
                my $append;
                if ($1 ne '') {
                  if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                    $append = 'receptor';
                  } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                    $append = 'kinase';
                  }
                  push @abstract_matches, "ABSTRACT EXACT 4: " .$syn . " $append";
                } else {
                  push @abstract_matches, "ABSTRACT EXACT 4: " .$syn;
                }
                $found = $found + $count_matches_syn2;
              }
            }
            if ($found == $count_matches) {
              last;
            }
          }
          if ($found <$count_matches) {
            my @matches = $abstract_text =~/((?:\S+)(?:\s*receptor|\s*kinase|\s*receptors|\s*kinases)?)\s*inhibitor\b/ig;
            foreach my $m (@matches) {
              if (length($m)>2 and lc($m) ne 'the' and !grep(/^EXACT 4: \Q$m\E$/i, @abstract_matches)) {push @abstract_matches, "ABSTRACT FREE 4: " . $m;};
            }
            $found = 0;
          }
        }
        $found=0; undef %start_or_end;
        $abstract_text = $abstract->to_literal();   
        if ($abstract_text =~/modulators of .+?/i) {
          my @count_matches = ($abstract_text =~/modulators of .+?/ig); 
          my $count_matches = @count_matches;
          foreach my $syn (sort { length($b) <=> length($a) } keys %abstract_matches) {
            if (($abstract_text =~/modulators of\s*(?:the)?\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/i) and $start_or_end{$-[0]}==0){
              $start_or_end{$+[0]} = 1;
              my @count_matches_syn2 = ($abstract_text =~/modulators of\s*(?:the)?\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig);
              my $count_matches_syn2 = @count_matches_syn2;
              for ( my $i = 1; $i < $count_matches_syn2 + 1; $i++ ) {
                my $append;
                if ($1 ne '') {
                  if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                    $append = 'receptor';
                  } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                    $append = 'kinase';
                  }
                  push @abstract_matches, "ABSTRACT EXACT 5: " .$syn . " $append";
                } else {
                  push @abstract_matches, "ABSTRACT EXACT 5: " .$syn;
                }
                $found = $found + $count_matches_syn2;
              }
            }
            if ($found == $count_matches) {
              last;
            }
          }
          if ($found <$count_matches) {
          my @matches = $abstract_text =~/modulators of\s*(?:the)?\s*((?:\S+)(?:\s*receptor|\s*kinase|\s*receptors|\s*kinases)?)/ig;
            foreach my $m (@matches) {
              if (length($m)>2 and lc($m) ne 'the' and !grep(/^EXACT 5: \Q$m\E$/i, @abstract_matches)) {push @abstract_matches, "ABSTRACT FREE 5: " . $m;};
            }
            $found = 0;
          }
        }
        $found=0; undef %start_or_end;
        $abstract_text = $abstract->to_literal();
        if ($abstract_text =~/modulation of .+?/i) {
          my @count_matches = ($abstract_text =~/modulation of .+?/ig); 
          my $count_matches = @count_matches;
          foreach my $syn (sort { length($b) <=> length($a) } keys %abstract_matches) {
            if (($abstract_text =~/modulation of\s*(?:the)?\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/i) and $start_or_end{$-[0]}==0){
              $start_or_end{$+[0]} = 1;
              my @count_matches_syn2 = ($abstract_text =~/modulation of\s*(?:the)?\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig);
              my $count_matches_syn2 = @count_matches_syn2;
              for ( my $i = 1; $i < $count_matches_syn2 + 1; $i++ ) {
                my $append;
                if ($1 ne '') {
                  if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                    $append = 'receptor';
                  } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                    $append = 'kinase';
                  }
                  push @abstract_matches, "ABSTRACT EXACT 6: " .$syn . " $append";
                } else {
                  push @abstract_matches, "ABSTRACT EXACT 6: " .$syn;
                }
                $found = $found + $count_matches_syn2;
              }
            }
            if ($found == $count_matches) {
              last;
            }
          }
          if ($found <$count_matches) {
            my @matches = $abstract_text =~/modulation of\s*(?:the)?\s*((?:\S+)(?:\s*receptor|\s*kinase|\s*receptors|\s*kinases)?)/ig;
            foreach my $m (@matches) {
              if (length($m)>2 and lc($m) ne 'the' and !grep(/^EXACT 6: \Q$m\E$/i, @abstract_matches)) {push @abstract_matches, "ABSTRACT FREE 6: " . $m;};
            }
            $found = 0;
          }
        }
        $found=0; undef %start_or_end;
        $abstract_text = $abstract->to_literal();   
        if ($abstract_text =~/targeting .+?/i) {
          my @count_matches = ($abstract_text =~/targeting .+?/ig); 
          my $count_matches = @count_matches;
          foreach my $syn (sort { length($b) <=> length($a) } keys %abstract_matches) {
            if (($abstract_text =~/targeting\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/i) and $start_or_end{$-[0]}==0){
              $start_or_end{$+[0]} = 1;
              my @count_matches_syn2 = ($abstract_text =~/targeting\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig);
              my $count_matches_syn2 = @count_matches_syn2;
              for ( my $i = 1; $i < $count_matches_syn2 + 1; $i++ ) {
                my $append;
                if ($1 ne '') {
                  if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                    $append = 'receptor';
                  } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                    $append = 'kinase';
                  }
                  push @abstract_matches, "ABSTRACT EXACT 7: " .$syn . " $append";
                } else {
                  push @abstract_matches, "ABSTRACT EXACT 7: " .$syn;
                }
                $found = $found + $count_matches_syn2;
              }
            }
            if ($found == $count_matches) {
              last;
            }
          }
          if ($found <$count_matches) {
            my @matches = $abstract_text =~/targeting\s*((?:\S+)(?:\s*receptor|\s*kinase|\s*receptors|\s*kinases)?)/ig;
            foreach my $m (@matches) {
              if (length($m)>2 and lc($m) ne 'the' and !grep(/^EXACT 7: \Q$m\E$/i, @abstract_matches)) {push @abstract_matches, "ABSTRACT FREE 7: " . $m;};
            }
            $found = 0;
          }
        }
        $found=0; undef %start_or_end;
        $abstract_text = $abstract->to_literal();   
        if ($abstract_text =~/.+? modulators/i) {
          my @count_matches = ($abstract_text =~/.+? modulators/ig); 
          my $count_matches = @count_matches;
          foreach my $syn (sort { length($b) <=> length($a) } keys %abstract_matches) {
            if (($abstract_text =~/\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*modulators/i) and $start_or_end{$+[0]}==0){
              $start_or_end{$+[0]} = 1;
              my @count_matches_syn2 = ($abstract_text =~/\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*modulators/ig);
              my $count_matches_syn2 = @count_matches_syn2;
              for ( my $i = 1; $i < $count_matches_syn2 + 1; $i++ ) {
                my $append;
                if ($1 ne '') {
                  if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                    $append = 'receptor';
                  } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                    $append = 'kinase';
                  }
                  push @abstract_matches, "ABSTRACT EXACT 8: " .$syn . " $append";
                } else {
                  push @abstract_matches, "ABSTRACT EXACT 8: " .$syn;
                }
                $found = $found + $count_matches_syn2;
              }
            }
            if ($found == $count_matches) {
              last;
            }
          }
          if ($found <$count_matches) {
            my @matches = $abstract_text =~/((?:\S+)(?:\s*receptor|\s*kinase|\s*receptors|\s*kinases)?)\s*modulators/ig;
            foreach my $m (@matches) {
              if (length($m)>2 and lc($m) ne 'the' and !grep(/^EXACT 8: \Q$m\E$/i, @abstract_matches)) {push @abstract_matches, "ABSTRACT FREE 8: " . $m;};
            }
            $found = 0;
          }
        }
        $found=0; undef %start_or_end;
        $abstract_text = $abstract->to_literal();   
        if ($abstract_text =~/binding specifically to .+?/i) {
          my @count_matches = ($abstract_text =~/binding specifically to .+?/ig); 
          my $count_matches = @count_matches;
          foreach my $syn (sort { length($b) <=> length($a) } keys %abstract_matches) {
            if (($abstract_text =~/binding specifically to\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/i) and $start_or_end{$-[0]}==0){
              $start_or_end{$+[0]} = 1;
              my @count_matches_syn2 = ($abstract_text =~/binding specifically to \b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig);
              my $count_matches_syn2 = @count_matches_syn2;
              for ( my $i = 1; $i < $count_matches_syn2 + 1; $i++ ) {
                my $append;
                if ($1 ne '') {
                  if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                    $append = 'receptor';
                  } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                    $append = 'kinase';
                  }
                  push @abstract_matches, "ABSTRACT EXACT 9: " .$syn . " $append";
                } else {
                  push @abstract_matches, "ABSTRACT EXACT 9: " .$syn;
                }
                $found = $found + $count_matches_syn2;
              }
            }
            if ($found == $count_matches) {
              last;
            }
          }
          if ($found <$count_matches) {
            my @matches = $abstract_text =~/binding specifically to\s*(\S+)\b(\s*receptor|\s*kinase|\s*receptors|\s*kinases)?/ig;
            foreach my $m (@matches) {
              if (length($m)>2 and lc($m) ne 'the' and !grep(/^EXACT 9: \Q$m\E$/i, @abstract_matches)) {push @abstract_matches, "ABSTRACT FREE 9: " . $m;};
            }
            $found = 0;
          }
        }
        $found=0; undef %start_or_end;
        $abstract_text = $abstract->to_literal();   
        if ($abstract_text =~/.+? mutants/i) {
          my @count_matches = ($abstract_text =~/.+? mutants/ig); 
          my $count_matches = @count_matches;
          foreach my $syn (sort { length($b) <=> length($a) } keys %abstract_matches) {
            if (($abstract_text =~/\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*mutants/i) and $start_or_end{$+[0]}==0) {
              $start_or_end{$+[0]} = 1;
              my @count_matches_syn2 = ($abstract_text =~/\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*mutants/ig);
              my $count_matches_syn2 = @count_matches_syn2;
              for ( my $i = 1; $i < $count_matches_syn2 + 1; $i++ ) {
                my $append;
                if ($1 ne '') {
                  if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                    $append = 'receptor';
                  } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                    $append = 'kinase';
                  }
                  push @abstract_matches, "ABSTRACT EXACT 12: " .$syn . " $append";
                } else {
                  push @abstract_matches, "ABSTRACT EXACT 12: " .$syn;
                }
                $found = $found + $count_matches_syn2;
              }
            }
            if ($found == $count_matches) {
              last;
            }
          }
          if ($found <$count_matches) {
            my @matches = $abstract_text =~/((?:\S+)(?:\s*receptor|\s*kinase|\s*receptors|\s*kinases)?)\s*mutants/ig;
            foreach my $m (@matches) {
              if (length($m)>2 and lc($m) ne 'the' and !grep(/^EXACT 12: \Q$m\E$/i, @abstract_matches)) {push @abstract_matches, "ABSTRACT FREE 12: " . $m;};
            }
            $found = 0;
          }
        }
        $found=0; undef %start_or_end;
        $abstract_text = $abstract->to_literal();   
        if ($abstract_text =~/inhibit .+?/i) {
          my @count_matches = ($abstract_text =~/inhibit .+?/ig); 
          my $count_matches = @count_matches;
          foreach my $syn (sort { length($b) <=> length($a) } keys %abstract_matches) {
            if (($abstract_text =~/inhibit\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/i) and $start_or_end{$-[0]}==0){
              $start_or_end{$+[0]} = 1;
              my @count_matches_syn2 = ($abstract_text =~/inhibit\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig);
              my $count_matches_syn2 = @count_matches_syn2;
              for ( my $i = 1; $i < $count_matches_syn2 + 1; $i++ ) {
                my $append;
                if ($1 ne '') {
                  if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                    $append = 'receptor';
                  } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                    $append = 'kinase';
                  }
                  push @abstract_matches, "ABSTRACT EXACT 13: " .$syn . " $append";
                } else {
                  push @abstract_matches, "ABSTRACT EXACT 13: " .$syn;
                }
                $found = $found + $count_matches_syn2;
              }
            }
            if ($found == $count_matches) {
              last;
            }
          }
          if ($found <$count_matches) {
            my @matches = $abstract_text =~/inhibit\s*((\S+)(?:\s*receptor|\s*kinase|\s*receptors|\s*kinases)?)/ig;
            foreach my $m (@matches) {
              if (length($m)>2 and lc($m) ne 'the' and !grep(/^EXACT 13: \Q$m\E$/i, @abstract_matches)) {push @abstract_matches, "ABSTRACT FREE 13: " . $m;};
            }
            $found = 0;
          }
        }
        $found=0; undef %start_or_end;
        $abstract_text = $abstract->to_literal();   
        if ($abstract_text =~/antibodies recogni(z|s)ing .+?/i) {
          my @count_matches = ($abstract_text =~/antibodies recogni(?:z|s)ing .+?/ig); 
          my $count_matches = @count_matches;
          foreach my $syn (sort { length($b) <=> length($a) } keys %abstract_matches) {
            if (($abstract_text =~/(?:monoclonal antibodies|antibodies)\s*recogni(?:z|s)ing\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/i) and $start_or_end{$-[0]}==0) {
              $start_or_end{$+[0]} = 1;
              my @count_matches_syn2 = ($abstract_text =~/(?:monoclonal antibodies|antibodies)\s*recogni(?:z|s)ing\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig);
              my $count_matches_syn2 = @count_matches_syn2;
              for ( my $i = 1; $i < $count_matches_syn2 + 1; $i++ ) {
                my $append;
                if ($1 ne '') {
                  if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                    $append = 'receptor';
                  } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                    $append = 'kinase';
                  }
                  push @abstract_matches, "ABSTRACT EXACT 14: " .$syn . " $append";
                } else {
                  push @abstract_matches, "ABSTRACT EXACT 14: " .$syn;
                }
                $found = $found + $count_matches_syn2;
              }
            }
            if ($found == $count_matches) {
              last;
            }
          }
          if ($found <$count_matches) {
            my @matches = $abstract_text =~/antibodies recogni(?:s|z)ing\s*((?:\S+)(?:\s*receptor|\s*kinase|\s*receptors|\s*kinases)?)/ig;
            foreach my $m (@matches) {
              if (length($m)>2 and lc($m) ne 'the' and !grep(/^EXACT 14: \Q$m\E$/i, @abstract_matches)) {push @abstract_matches, "ABSTRACT FREE 14: " . $m;};
            }
            $found =0; 
          }
        }
        $found=0; undef %start_or_end;
        $abstract_text = $abstract->to_literal();   
        if ($abstract_text =~/modulating the .+?/i) {
          my @count_matches = ($abstract_text =~/modulating the .+?/ig); 
          my $count_matches = @count_matches;
          foreach my $syn (sort { length($b) <=> length($a) } keys %abstract_matches) {
            if (($abstract_text =~/modulating the\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/i) and $start_or_end{$-[0]}==0) {
              $start_or_end{$+[0]} = 1;
              my @count_matches_syn2 = ($abstract_text =~/modulating the\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig);
              my $count_matches_syn2 = @count_matches_syn2;
              for ( my $i = 1; $i < $count_matches_syn2 + 1; $i++ ) {
                my $append;
                if ($1 ne '') {
                  if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                    $append = 'receptor';
                  } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                    $append = 'kinase';
                  }
                  push @abstract_matches, "ABSTRACT EXACT 17: " .$syn . " $append";
                } else {
                  push @abstract_matches, "ABSTRACT EXACT 17: " .$syn;
                }
                $found = $found + $count_matches_syn2;
              }
            }
            if ($found == $count_matches) {
              last;
            }
          }
          if ($found <$count_matches) {
            my @matches = $abstract_text =~/modulating the\s*((?:\S+)(?:\s*receptor|\s*kinase|\s*receptors|\s*kinases)?)/ig;
            foreach my $m (@matches) {
              if (length($m)>2 and lc($m) ne 'the' and !grep(/^EXACT 17: \Q$m\E$/i, @abstract_matches)) {push @abstract_matches, "ABSTRACT FREE 17: " . $m;};
            }
            $found = 0;
          }
        }  
        $found=0; undef %start_or_end;
        $abstract_text = $abstract->to_literal();
        if ($abstract_text =~/selective .+? inhibitors/i) { 
          my @count_matches = ($abstract_text =~/selective .+? inhibitors/ig); 
          my $count_matches = @count_matches;
          foreach my $syn (sort { length($b) <=> length($a) } keys %abstract_matches) {
            if ($abstract_text =~/selective\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*inhibitors/i) {
              my @count_matches_syn2 = ($abstract_text =~/selective\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*inhibitors/ig);
              my $count_matches_syn2 = @count_matches_syn2;
              for ( my $i = 1; $i < $count_matches_syn2 + 1; $i++ ) {
                my $append;
                if ($1 ne '') {
                  if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                    $append = 'receptor';
                  } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                    $append = 'kinase';
                  }
                  push @abstract_matches, "ABSTRACT EXACT 18: " .$syn . " $append";
                } else {
                  push @abstract_matches, "ABSTRACT EXACT 18: " .$syn;
                }
                $found = $found + $count_matches_syn2;
              }
            }
            if ($found == $count_matches) {
              last;
            }
          }
          if ($found <$count_matches) {
            my @matches = $abstract_text =~/selective\s*((?:\S+)(?:\s*receptor|\s*kinase|\s*receptors|\s*kinases)?)\s*inhibitors/ig;
            foreach my $m (@matches) {
              if (length($m)>2 and lc($m) ne 'the' and !grep(/^EXACT 18: \Q$m\E$/i, @abstract_matches)) {push @abstract_matches, "ABSTRACT FREE 18: " . $m;};
            }
            $found =0; 
          }
        } 
        $found=0; undef %start_or_end;
        $abstract_text = $abstract->to_literal();
        if ($abstract_text =~/.+? antagonist/i) {
          my @count_matches = ($abstract_text =~/.+? antagonist/ig);
          my $count_matches = @count_matches;
          foreach my $syn (sort { length($b) <=> length($a) } keys %abstract_matches) {
            if (($abstract_text =~/\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*(?:non competitive|non-competitive|competitive)?\s*(?:antagonists|antagonist\b)/i) and $start_or_end{$+[0]}==0){
              $start_or_end{$+[0]} = 1;
              my @count_matches_syn2 = ($abstract_text =~/\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*(?:non competitive|non-competitive|competitive)?\s*(?:antagonists|antagonist\b)/ig);
              my $count_matches_syn2 = @count_matches_syn2;
              for ( my $i = 1; $i < $count_matches_syn2 + 1; $i++ ) {
                my $append;
                if ($1 ne '') {
                  if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                    $append = 'receptor';
                  } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                    $append = 'kinase';
                  }
                  push @abstract_matches, "ABSTRACT EXACT 19: " .$syn . " $append";
                } else {
                  push @abstract_matches, "ABSTRACT EXACT 19: " .$syn;
                }
                $found = $found + $count_matches_syn2;
              }
            }
            if ($found == $count_matches) {
              last;
            }
          }
          if ($found <$count_matches) {
            my @matches = $abstract_text =~/((?:\S+)(?:\s*receptor|\s*kinase|\s*receptors|\s*kinases)?)\s*(?:non competitive|non-competitive|competitive)?\s*(?:antagonists|antagonist\b)/ig;
            foreach my $m (@matches) {
              if (length($m)>2 and lc($m) ne 'the' and !grep(/^EXACT 19: \Q$m\E$/i, @abstract_matches)) {push @abstract_matches, "ABSTRACT FREE 19: " . $m;};
            }
            $found = 0;
          }
        }
        $found=0; undef %start_or_end;
        $abstract_text = $abstract->to_literal();
        if ($abstract_text =~/.+? \bagonist/i) {
          my @count_matches = ($abstract_text =~/.+? \bagonist/ig); 
          my $count_matches = @count_matches;
          foreach my $syn (sort { length($b) <=> length($a) } keys %abstract_matches) {
            if (($abstract_text =~/\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*(?:\bagonist|\bagonists|partial agonist|partial agonists|inverse agonist|inverse agonists)/i) and $start_or_end{$+[0]}==0) {
              $start_or_end{$+[0]} = 1;
              my @count_matches_syn2 = ($abstract_text =~/\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*(?:\bagonist|\bagonists|partial agonist|partial agonists|inverse agonist|inverse agonists)/ig);
              my $count_matches_syn2 = @count_matches_syn2;
              for ( my $i = 1; $i < $count_matches_syn2 + 1; $i++ ) {
                my $append;
                if ($1 ne '') {
                  if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                    $append = 'receptor';
                  } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                    $append = 'kinase';
                  }
                  push @abstract_matches, "ABSTRACT EXACT 20: " .$syn . " $append";
                } else {
                  push @abstract_matches, "ABSTRACT EXACT 20: " .$syn;
                }
                $found = $found + $count_matches_syn2;
              }
            }
            if ($found == $count_matches) {
              last;
            }
          }
          if ($found <$count_matches) {
            my @matches = $abstract_text =~/((?:\S+)(?:\s*receptor|\s*kinase|\s*receptors|\s*kinases)?)\s*(?:\bagonist|\bagonists|partial agonist|partial agonists|inverse agonist|inverse agonists)/ig;
            foreach my $m (@matches) {
              if (length($m)>2 and lc($m) ne 'the' and !grep(/^EXACT 20: \Q$m\E$/i, @abstract_matches)) {push @abstract_matches, "ABSTRACT FREE 20: " . $m;};
            }
            $found = 0;
          }
        }
        $found=0; undef %start_or_end;
        $abstract_text = $abstract->to_literal();   
        if ($abstract_text =~/.+? selective binding compounds/i) {
          my @count_matches = ($abstract_text =~/.+? selective binding compounds/ig); 
          my $count_matches = @count_matches;
          foreach my $syn (sort { length($b) <=> length($a) } keys %abstract_matches) {
            if (($abstract_text =~/\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*selective binding compounds/i) and $start_or_end{$+[0]}==0) {
              $start_or_end{$+[0]} = 1;
              my @count_matches_syn2 = ($abstract_text =~/\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*selective binding compounds/ig);
              my $count_matches_syn2 = @count_matches_syn2;
              for ( my $i = 1; $i < $count_matches_syn2 + 1; $i++ ) {
                my $append;
                if ($1 ne '') {
                  if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                    $append = 'receptor';
                  } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                    $append = 'kinase';
                  }
                  push @abstract_matches, "ABSTRACT EXACT 21: " .$syn . " $append";
                } else {
                  push @abstract_matches, "ABSTRACT EXACT 21: " .$syn;
                }
                $found = $found + $count_matches_syn2;
              }
            }
            if ($found == $count_matches) {
              last;
            }
          }
          if ($found <$count_matches) {
          my @matches = $abstract_text =~/((?:\S+)(?:\s*receptor|\s*kinase|\s*receptors|\s*kinases)?)\s*selective binding compounds/ig;
            foreach my $m (@matches) {
              if (length($m)>2 and lc($m) ne 'the' and !grep(/^EXACT 21: \Q$m\E$/i, @abstract_matches)) {push @abstract_matches, "ABSTRACT FREE 21: " . $m;};
            }
            $found = 0;
          }
        } 
        $found=0; undef %start_or_end;
        $abstract_text = $abstract->to_literal();   
        if ($abstract_text =~/activity of .+?/i) {
          my @count_matches = ($abstract_text =~/activity of .+?/ig); 
          my $count_matches = @count_matches;
          foreach my $syn (sort { length($b) <=> length($a) } keys %abstract_matches) {
            if (($abstract_text =~/activity of \b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/i) and $start_or_end{$-[0]}==0){
              $start_or_end{$+[0]} = 1;
              my @count_matches_syn2 = ($abstract_text =~/activity of \b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig);
              my $count_matches_syn2 = @count_matches_syn2;
              for ( my $i = 1; $i < $count_matches_syn2 + 1; $i++ ) {
                my $append;
                if ($1 ne '') {
                  if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                    $append = 'receptor';
                  } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                    $append = 'kinase';
                  }
                  push @abstract_matches, "ABSTRACT EXACT 24: " .$syn . " $append";
                } else {
                  push @abstract_matches, "ABSTRACT EXACT 24: " .$syn;
                }
                $found = $found + $count_matches_syn2;
              }
            }
            if ($found == $count_matches) {
              last;
            }
          }
          if ($found <$count_matches) {
            my @matches = $abstract_text =~/activity of\s*((?:\S+)(?:\s*receptor|\s*kinase|\s*receptors|\s*kinases)?)/ig;
            foreach my $m (@matches) {
              if (length($m)>2 and lc($m) ne 'the' and !grep(/^EXACT 24: \Q$m\E$/i, @abstract_matches)) {push @abstract_matches, "ABSTRACT FREE 24: " . $m;};
            }
            $found =0; 
          }
        }  
        $found=0; undef %start_or_end;
        $abstract_text = $abstract->to_literal();
        if ($abstract_text =~/.+? antibodies/i) {
          my @count_matches = ($abstract_text =~/(?:anti-)?\s*.+?\s*(?:specific)?\s*(?:monoclonal)?\s*\bantibodies/ig);
          my $count_matches = @count_matches;
          foreach my $syn (sort { length($b) <=> length($a) } keys %abstract_matches) {
            if (($abstract_text =~/(?:anti-)?\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*(?:specific)?\s*(?:monoclonal antibodies|antibodies)/i) and $start_or_end{$+[0]}==0) {
              $start_or_end{$+[0]} = 1;
              my @count_matches_syn2 = $abstract_text =~/(?:anti-)?\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*(?:specific)?\s*(?:monoclonal antibodies|antibodies)/ig;
              my $count_matches_syn2 = @count_matches_syn2;
              for ( my $i = 1; $i < $count_matches_syn2 + 1; $i++ ) {
                my $append;
                if ($1 ne '') {
                  if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                    $append = 'receptor';
                  } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                    $append = 'kinase';
                  }
                  push @abstract_matches, "ABSTRACT EXACT 25: " .$syn . " $append";
                } else {
                  push @abstract_matches, "ABSTRACT EXACT 25: " .$syn;
                }
                $found = $found + $count_matches_syn2;
              }
            }
            if ($found == $count_matches) {
              last;
            }
          }
          if ($found <$count_matches) {
            my @matches = $abstract_text =~/(?:anti-)?\s*((?:\S+)(?:\s*receptor|\s*kinase|\s*receptors|\s*kinases)?)\s*(?:specific)?\s*(?:monoclonal antibodies|antibodies)/ig;
            foreach my $m (@matches) {
              if (length($m)>2 and lc($m) ne 'the' and !grep(/^EXACT 25: \Q$m\E$/i, @abstract_matches) and lc($m)!~/anti-/) {push @abstract_matches, "ABSTRACT FREE 25: " . $m;};
            }
            $found = 0;
          }
        } 
        $found=0; undef %start_or_end;
        $abstract_text = $abstract->to_literal();
        if ($abstract_text =~/.+? activity/i) {
          my @count_matches = ($abstract_text =~/.+?\s*(?:\binhibitory|inhibiting)?\s*\bactivity/ig);
          my $count_matches = @count_matches;
          foreach my $syn (sort { length($b) <=> length($a) } keys %abstract_matches) {
            if (($abstract_text =~/\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*(?:inhibitory|inhibiting|antagonistic)?\s*\bactivity/i) and $start_or_end{$+[0]}==0){
              $start_or_end{$+[0]} = 1;
              my @count_matches_syn2 = ($abstract_text =~/\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*(?:inhibitory|inhibiting|antagonistic)?\s*\bactivity/ig);
              my $count_matches_syn2 = @count_matches_syn2;
              for ( my $i = 1; $i < $count_matches_syn2 + 1; $i++ ) {
                my $append;
                if ($1 ne '') {
                  if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                    $append = 'receptor';
                  } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                    $append = 'kinase';
                  }
                  push @abstract_matches, "ABSTRACT EXACT 26: " .$syn . " $append";
                } else {
                  push @abstract_matches, "ABSTRACT EXACT 26: " .$syn;
                }
                $found = $found + $count_matches_syn2;
              }
            }
            if ($found == $count_matches) {
              last;
            }
          }
          if ($found <$count_matches) {
            my @matches = $abstract_text =~/(\S+(?:\s*receptor|\s*kinase|\s*receptors|\s*kinases)?)\s*(?:inhibitory|inhibiting|antagonistic)?\s*\bactivity/ig;
            foreach my $m (@matches) {
              if (length($m)>2 and lc($m) ne 'the' and !grep(/^EXACT 26: \Q$m\E$/i, @abstract_matches)) {push @abstract_matches, "ABSTRACT FREE 26: " . $m;};
            }
            $found = 0;
          }
        }
        $found=0; undef %start_or_end;
        $abstract_text = $abstract->to_literal();
        if ($abstract_text =~/inhibitor of .+?/i) {
          my @count_matches = ($abstract_text =~/inhibitor of .+?/ig); 
          my $count_matches = @count_matches;
          foreach my $syn (sort { length($b) <=> length($a) } keys %abstract_matches) {
            if (($abstract_text =~/inhibitor of\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/i) and $start_or_end{$-[0]}==0) {
              $start_or_end{$+[0]} = 1;
              my @count_matches_syn2 = ($abstract_text =~/inhibitor of\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig);
              my $count_matches_syn2 = @count_matches_syn2;
              for ( my $i = 1; $i < $count_matches_syn2 + 1; $i++ ) {
                my $append;
                if ($1 ne '') {
                  if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                    $append = 'receptor';
                  } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                    $append = 'kinase';
                  }
                  push @abstract_matches, "ABSTRACT EXACT 27: " .$syn . " $append";
                } else {
                  push @abstract_matches, "ABSTRACT EXACT 27: " .$syn;
                }
                $found = $found + $count_matches_syn2;
              }
            }
            if ($found == $count_matches) {
              last;
            }
          }
          if ($found <$count_matches) {
          my @matches = $abstract_text =~/inhibitor of\s*(?:(\S+)(\s*receptor|\s*kinase|\s*receptors|\s*kinases)?)/ig;
            foreach my $m (@matches) {
              if (length($m)>2 and lc($m) ne 'the' and !grep(/^EXACT 27: \Q$m\E$/i, @abstract_matches)) {push @abstract_matches, "ABSTRACT FREE 27: " . $m;};
            }
            $found = 0;
          }
        } 
        $found=0; undef %start_or_end;
        $abstract_text = $abstract->to_literal();   
        if ($abstract_text =~/.+? binding/i) {
          my @count_matches = ($abstract_text =~/.+? binding/ig); 
          my $count_matches = @count_matches;
          foreach my $syn (sort { length($b) <=> length($a) } keys %abstract_matches) {
            if (($abstract_text =~/\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*binding/i) and $start_or_end{$+[0]}==0) {
              $start_or_end{$+[0]} = 1;
              my @count_matches_syn2 = ($abstract_text =~/\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*binding/ig);
              my $count_matches_syn2 = @count_matches_syn2;
              for ( my $i = 1; $i < $count_matches_syn2 + 1; $i++ ) {
                my $append;
                if ($1 ne '') {
                  if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                    $append = 'receptor';
                  } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                    $append = 'kinase';
                  }
                  push @abstract_matches, "ABSTRACT EXACT 29: " .$syn . " $append";
                } else {
                  push @abstract_matches, "ABSTRACT EXACT 29: " .$syn;
                }
                $found = $found + $count_matches_syn2;
              }
            }
            if ($found == $count_matches) {
              last;
            }
          }
          if ($found <$count_matches) {
            my @matches = $abstract_text =~/((?:\S+)(?:\s*receptor|\s*kinase|\s*receptors|\s*kinases)?)\s*binding/ig;
            foreach my $m (@matches) {
              if (length($m)>2 and lc($m) ne 'the' and !grep(/^EXACT 29: \Q$m\E$/i, @abstract_matches)) {push @abstract_matches, "ABSTRACT FREE 29: " . $m;};
            }
            $found = 0;
          }
        }
        $found=0; undef %start_or_end;
        $abstract_text = $abstract->to_literal();
        if ($abstract_text =~/antibodies directed against .+?/i) {
          my @count_matches = ($abstract_text =~/antibodies directed against .+?/ig); 
          my $count_matches = @count_matches;
          foreach my $syn (sort { length($b) <=> length($a) } keys %abstract_matches) {
            if (($abstract_text =~/(?:monoclonal antibodies|antibodies)\s*directed against\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/i) and $start_or_end{$-[0]}==0){
              $start_or_end{$+[0]} = 1;
              my @count_matches_syn2 = ($abstract_text =~/(?:monoclonal antibodies|antibodies)\s*directed against\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig);
              my $count_matches_syn2 = @count_matches_syn2;
              for ( my $i = 1; $i < $count_matches_syn2 + 1; $i++ ) {
                my $append;
                if ($1 ne '') {
                  if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                    $append = 'receptor';
                  } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                    $append = 'kinase';
                  }
                  push @abstract_matches, "ABSTRACT EXACT 30: " .$syn . " $append";
                } else {
                  push @abstract_matches, "ABSTRACT EXACT 30: " .$syn;
                }
                $found = $found + $count_matches_syn2;
              }
            }
            if ($found == $count_matches) {
              last;
            }
          }
          if ($found <$count_matches) {
            my @matches = $abstract_text =~/(?:monoclonal antibodies|antibodies)\s*directed against\s*((?:\b(\S+)\b)(?:\s*receptor|\s*kinase|\s*receptors|\s*kinases)?)/ig;
            foreach my $m (@matches) {
              if (length($m)>2 and lc($m) ne 'the' and !grep(/^EXACT 30: \Q$m\E$/i, @abstract_matches)) {push @abstract_matches, "ABSTRACT FREE 30: " . $m;};
            }
            $found = 0;
          }
        }
        $found=0; undef %start_or_end;
        $abstract_text = $abstract->to_literal();
        if ($abstract_text =~/treatment of .+? related/i) {
          my @count_matches = ($abstract_text =~/treatment of .+? related/ig); 
          my $count_matches = @count_matches;
          foreach my $syn (sort { length($b) <=> length($a) } keys %abstract_matches) {
            if ($abstract_text =~/treatment of\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*related/i) {
              my @count_matches_syn2 = ($abstract_text =~/treatment of\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*related/ig);
              my $count_matches_syn2 = @count_matches_syn2;
              for ( my $i = 1; $i < $count_matches_syn2 + 1; $i++ ) {
                my $append;
                if ($1 ne '') {
                  if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                    $append = 'receptor';
                  } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                    $append = 'kinase';
                  }
                  push @abstract_matches, "ABSTRACT EXACT 31: " .$syn . " $append";
                } else {
                  push @abstract_matches, "ABSTRACT EXACT 31: " .$syn;
                }
                $found = $found + $count_matches_syn2;
              }
            }
            if ($found == $count_matches) {
              last;
            }
          }
          if ($found <$count_matches) {
            my @matches = $abstract_text =~/treatment of\s*((?:\S+)(?:\s*receptor|\s*kinase|\s*receptors|\s*kinases)?)\s*related/ig;
            foreach my $m (@matches) {
              if (length($m)>2 and lc($m) ne 'the' and !grep(/^EXACT 31: \Q$m\E$/i, @abstract_matches)) {push @abstract_matches, "ABSTRACT FREE 31: " . $m;};
            }
            $found = 0;
          }
        }
        $found=0; undef %start_or_end;
        $abstract_text = $abstract->to_literal();
        if ($abstract_text =~/antibody for .+?/i) {
          my @count_matches = ($abstract_text =~/antibody for .+?/ig); 
          my $count_matches = @count_matches;
          foreach my $syn (sort { length($b) <=> length($a) } keys %abstract_matches) {
            if (($abstract_text =~/(?:monoclonal antibody|antibody)\s*for\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/i) and $start_or_end{$-[0]}==0) {
              $start_or_end{$+[0]} = 1;
              my @count_matches_syn2 = ($abstract_text =~/(?:monoclonal antibody|antibody)\s*for\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig);
              my $count_matches_syn2 = @count_matches_syn2;
              for ( my $i = 1; $i < $count_matches_syn2 + 1; $i++ ) {
                my $append;
                if ($1 ne '') {
                  if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                    $append = 'receptor';
                  } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                    $append = 'kinase';
                  }
                  push @abstract_matches, "ABSTRACT EXACT 32: " .$syn . " $append";
                } else {
                  push @abstract_matches, "ABSTRACT EXACT 32: " .$syn;
                }
                $found = $found + $count_matches_syn2;
              }
            }
            if ($found == $count_matches) {
              last;
            }
          }
          if ($found <$count_matches) {
            my @matches = $abstract_text =~/(?:monoclonal antibody|antibody)\s*for\s*(\S+(?:\s*receptor|\s*kinase|\s*receptors|\s*kinases)?)/ig;
            foreach my $m (@matches) {
              if (length($m)>2 and lc($m) ne 'the' and !grep(/^EXACT 32: \Q$m\E$/i, @abstract_matches)) {push @abstract_matches, "ABSTRACT FREE 32: " . $m;};
            }
            $found = 0;
          }
        }
        $found=0; undef %start_or_end;
        $abstract_text = $abstract->to_literal();
        if ($abstract_text =~/anti-.+?\s*(?:monoclonal)?\s*antibody/i) {
          my @count_matches = ($abstract_text =~/anti-.+?\s*(?:monoclonal)?\s*antibody/ig);
          my $count_matches = @count_matches;
          foreach my $syn (sort { length($b) <=> length($a) } keys %abstract_matches) {
            if ($abstract_text =~/anti-\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*(?:monoclonal antibody|antibody)/i) {
              my @count_matches_syn2 = ($abstract_text =~/anti-\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*(?:monoclonal antibody|antibody)/ig);
              my $count_matches_syn2 = @count_matches_syn2;
              for ( my $i = 1; $i < $count_matches_syn2 + 1; $i++ ) {
                my $append;
                if ($1 ne '') {
                  if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                    $append = 'receptor';
                  } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                    $append = 'kinase';
                  }
                  push @abstract_matches, "ABSTRACT EXACT 33: " .$syn . " $append";
                } else {
                  push @abstract_matches, "ABSTRACT EXACT 33: " .$syn;
                }
                $found = $found + $count_matches_syn2;
              }
            }
            if ($found == $count_matches) {
              last;
            }
          }
          if ($found <$count_matches) {
            my @matches = $abstract_text =~/anti-((?:\S+)(?:\s*receptor|\s*kinase|\s*receptors|\s*kinases)?)\s*(?:monoclonal antibody|antibody)/ig;
            foreach my $m (@matches) {
              if (length($m)>2 and lc($m) ne 'the' and !grep(/^EXACT 33: \Q$m\E$/i, @abstract_matches)) {push @abstract_matches, "ABSTRACT FREE 33: " . $m;};
            }
            $found = 0;
          }
        }
        $found=0; undef %start_or_end;
        $abstract_text = $abstract->to_literal();
        if ($abstract_text =~/human anti-.+?/i and $abstract_text !~/human anti-.+?\s*antibody/i) {
          my @count_matches = ($abstract_text =~/human anti-.+?/ig); 
          my $count_matches = @count_matches;
          foreach my $syn (sort { length($b) <=> length($a) } keys %abstract_matches) {
            if (($abstract_text =~/human anti-\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/i) and $start_or_end{$-[0]}==0) {
              my @count_matches_syn2 = ($abstract_text =~/human anti-\Q$syn\E\b/ig);
              my $count_matches_syn2 = @count_matches_syn2;
              $start_or_end{$+[0]} = 1;
              for ( my $i = 1; $i < $count_matches_syn2 + 1; $i++ ) {
                my $append;
                if ($1 ne '') {
                  if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                    $append = 'receptor';
                  } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                    $append = 'kinase';
                  }
                  push @abstract_matches, "ABSTRACT EXACT 34: " .$syn . " $append";
                } else {
                  push @abstract_matches, "ABSTRACT EXACT 34: " .$syn;
                }
                $found = $found + $count_matches_syn2;
              }
            }
            if ($found == $count_matches) {
              last;
            }
          }
          if ($found <$count_matches) {
            my @matches = $abstract_text =~/human anti-((?:\S+)(?:\s*receptor|\s*kinase|\s*receptors|\s*kinases)?)/ig;
            foreach my $m (@matches) {
              if (length($m)>2 and lc($m) ne 'the' and !grep(/^EXACT 34: \Q$m\E$/i, @abstract_matches)) {push @abstract_matches, "ABSTRACT FREE 34: " . $m;};
            }
            $found = 0;
          }
        }
        $found=0;
        $found=0; undef %start_or_end;
        $abstract_text = $abstract->to_literal();
        if ($abstract_text =~/antibodies to .+?/i) {
          my @count_matches = ($abstract_text =~/antibodies to .+?/ig); 
          my $count_matches = @count_matches;
          foreach my $syn (sort { length($b) <=> length($a) } keys %abstract_matches) {
            if (($abstract_text =~/(?:monoclonal antibodies to|antibodies to)\s*(?:human)?\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/i) and $start_or_end{$-[0]}==0) {
              $start_or_end{$+[0]} = 1;
              my @count_matches_syn2 = ($abstract_text =~/(?:monoclonal antibodies to|antibodies to)\s*(?:human)?\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig);
              my $count_matches_syn2 = @count_matches_syn2;
              for ( my $i = 1; $i < $count_matches_syn2 + 1; $i++ ) {
                my $append;
                if ($1 ne '') {
                  if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                    $append = 'receptor';
                  } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                    $append = 'kinase';
                  }
                  push @abstract_matches, "ABSTRACT EXACT 35: " .$syn . " $append";
                } else {
                  push @abstract_matches, "ABSTRACT EXACT 35: " .$syn;
                }
                $found = $found + $count_matches_syn2;
              }
            }
            if ($found == $count_matches) {
              last;
            }
          }
          if ($found <$count_matches) {
            my @matches = $abstract_text =~/(?:monoclonal antibodies to|antibodies to)\s*(?:human)?\s*((?:\S+)(?:\s*receptor|\s*kinase|\s*receptors|\s*kinases)?)/ig;
            foreach my $m (@matches) {
              if (length($m)>2 and lc($m) ne 'the' and !grep(/^EXACT 35: \Q$m\E$/i, @abstract_matches)) {push @abstract_matches, "ABSTRACT FREE 35: " . $m;};
            }
            $found = 0;
          }
        } 
        $found=0; undef %start_or_end;
        $abstract_text = $abstract->to_literal();
        if ($abstract_text =~/high .+? affinity/i) {
          my @count_matches = ($abstract_text =~/high .+? affinity/ig); 
          my $count_matches = @count_matches;
          foreach my $syn (sort { length($b) <=> length($a) } keys %abstract_matches) {
            if ($abstract_text =~/high\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*affinity/i) {
              my @count_matches_syn2 = ($abstract_text =~/high\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*affinity/ig);
              my $count_matches_syn2 = @count_matches_syn2;
              for ( my $i = 1; $i < $count_matches_syn2 + 1; $i++ ) {
                my $append;
                if ($1 ne '') {
                  if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                    $append = 'receptor';
                  } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                    $append = 'kinase';
                  }
                  push @abstract_matches, "ABSTRACT EXACT 36: " .$syn . " $append";
                } else {
                  push @abstract_matches, "ABSTRACT EXACT 36: " .$syn;
                }
                $found = $found + $count_matches_syn2;
              }
            }
            if ($found == $count_matches) {
              last;
            }
          }
          if ($found <$count_matches) {
            my @matches = $abstract_text =~/(?:high\s*((?:\S+)(?:\s*receptor|\s*kinase|\s*receptors|\s*kinases)?)\s*affinity)/ig;
            foreach my $m (@matches) {
              if (length($m)>2 and lc($m) ne 'the' and !grep(/^EXACT 36: \Q$m\E$/i, @abstract_matches)) {push @abstract_matches, "ABSTRACT FREE 36: " . $m;};
            }
            $found = 0;
          }
        }  
        $found=0; undef %start_or_end;
        $abstract_text = $abstract->to_literal(); 
        if ($abstract_text =~/inhibiting .+?/i) {
          my @count_matches = ($abstract_text =~/inhibiting .+?/ig); 
          my $count_matches =  @count_matches;
          foreach my $syn (sort { length($b) <=> length($a) } keys %abstract_matches) {
            if (($abstract_text =~/inhibiting\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/i) and $start_or_end{$-[0]}==0) {
              $start_or_end{$+[0]} = 1;
              my @count_matches_syn2 = ($abstract_text =~/inhibiting\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig);
              my $count_matches_syn2 = @count_matches_syn2;
              for ( my $i = 1; $i < $count_matches_syn2 + 1; $i++ ) {
                my $append;
                if ($1 ne '') {
                  if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                    $append = 'receptor';
                  } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                    $append = 'kinase';
                  }
                  push @abstract_matches, "ABSTRACT EXACT 39: " .$syn . " $append";
                } else {
                  push @abstract_matches, "ABSTRACT EXACT 39: " .$syn;
                }
                $found = $found + $count_matches_syn2;
              }
            }
            if ($found == $count_matches) {
              last;
            }
          }
          if ($found <$count_matches) {
            my @matches = $abstract_text =~/inhibiting\s*((?:\S+)(?:\s*receptor|\s*kinase|\s*receptors|\s*kinases)?)/ig;
            foreach my $m (@matches) {
              if (length($m)>2 and lc($m) ne 'the' and !grep(/^EXACT 39: \Q$m\E$/i, @abstract_matches)) {push @abstract_matches, "ABSTRACT FREE 39: " . $m;};
            }
            $found = 0;
          }
        }  
        $found=0; undef %start_or_end;
        $abstract_text = $abstract->to_literal();
        if ($abstract_text =~/blocks|block .+/i) {
          my @count_matches = ($abstract_text =~/(blocks|block)\b(?:the)?\b.+?/ig);
          my $count_matches = @count_matches;
          foreach my $syn (sort { length($b) <=> length($a) } keys %abstract_matches) {
            if (($abstract_text =~/(?:blocks\b|block\b)\s*(?:the)?\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/i) and $start_or_end{$-[0]}==0) {
              $start_or_end{$+[0]} = 1;
              my @count_matches_syn2 = ($abstract_text =~/(?:blocks\b|block\b)\s*(?:the)?\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig);
              my $count_matches_syn2 = @count_matches_syn2;
              for ( my $i = 1; $i < $count_matches_syn2 + 1; $i++ ) {
                my $append;
                if ($1 ne '') {
                  if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                    $append = 'receptor';
                  } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                    $append = 'kinase';
                  }
                  push @abstract_matches, "ABSTRACT EXACT 40: " .$syn . " $append";
                } else {
                  push @abstract_matches, "ABSTRACT EXACT 40: " .$syn;
                }
                $found = $found + $count_matches_syn2;
              }
            }
            if ($found == $count_matches) {
              last;
            }
          }
          if ($found <$count_matches) {
            my @matches = $abstract_text =~/(?:blocks\b|block\b)\s*(?:the)?\s*((?:\S+)(?:\s*receptor|\s*kinase|\s*receptors|\s*kinases)?)/ig;
            foreach my $m (@matches) {
              if (length($m)>2 and lc($m) ne 'the' and !grep(/^EXACT 40: \Q$m\E$/i, @abstract_matches)) {push @abstract_matches, "ABSTRACT FREE 40: " . $m;};
            }
            $found = 0;
          }
        }
        $found=0; undef %start_or_end;
        $abstract_text = $abstract->to_literal();
        if ($abstract_text =~/blocking .+/i) {
          my @count_matches = ($abstract_text =~/blocking\b\s*(?:the\b|a\b|an\b)?\s*.+?/ig);
          my $count_matches = @count_matches;
          foreach my $syn (sort { length($b) <=> length($a) } keys %abstract_matches) {
            if (($abstract_text =~/blocking\b\s*(?:the\b|a\b|an\b)?\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/i) and $start_or_end{$-[0]}==0) {
              $start_or_end{$+[0]} = 1;
              my @count_matches_syn2 = ($abstract_text =~/blocking\b\s*(?:the\b|a\b|an\b)?\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig);
              my $count_matches_syn2 = @count_matches_syn2;
              for ( my $i = 1; $i < $count_matches_syn2 + 1; $i++ ) {
                my $append;
                if ($1 ne '') {
                  if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                    $append = 'receptor';
                  } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                    $append = 'kinase';
                  }
                  push @abstract_matches, "ABSTRACT EXACT 41: " .$syn . " $append";
                } else {
                  push @abstract_matches, "ABSTRACT EXACT 41: " .$syn;
                }
                $found = $found + $count_matches_syn2;
              }
            }
            if ($found == $count_matches) {
              last;
            }
          }
          if ($found <$count_matches) {
            my @matches = $abstract_text =~/blocking\b\s*(?:the\b|a\b|an\b)?\s*((?:\S+)(?:\s*receptor|\*kinase|\*receptors|\s*kinases)?)/ig;
            foreach my $m (@matches) {
              if (length($m)>2 and lc($m) ne 'the' and !grep(/^EXACT 41: \Q$m\E$/i, @abstract_matches)) {push @abstract_matches, "ABSTRACT FREE 41: " . $m;};
            }
            $found = 0;
          }
        }
        $found=0; undef %start_or_end;
        $abstract_text = $abstract->to_literal();
        if ($abstract_text =~/ligand|ligands for .+/i) {
          my @count_matches = ($abstract_text =~/(?:ligand|ligands)\s*(?:for the\b|for\b).+?/ig);
          my $count_matches = @count_matches;
          foreach my $syn (sort { length($b) <=> length($a) } keys %abstract_matches) {
            if (($abstract_text =~/(?:ligand|ligands)\s*(?:for the\b|for\b)\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/i) and $start_or_end{$-[0]}==0) {
              $start_or_end{$+[0]} = 1;
              my @count_matches_syn2 = ($abstract_text =~/(?:ligand|ligands)\s*(?:for the\b|for\b)\s*\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig);
              my $count_matches_syn2 = @count_matches_syn2;
              for ( my $i = 1; $i < $count_matches_syn2 + 1; $i++ ) {
                my $append;
                if ($1 ne '') {
                  if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                    $append = 'receptor';
                  } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                    $append = 'kinase';
                  }
                  push @abstract_matches, "ABSTRACT EXACT 42: " .$syn . " $append";
                } else {
                  push @abstract_matches, "ABSTRACT EXACT 42: " .$syn;
                }
                $found = $found + $count_matches_syn2;
              }
            }
            if ($found == $count_matches) {
              last;
            }
          }
          if ($found <$count_matches) {
            my @matches = $abstract_text =~/(?:ligand\b|ligands\b)\s*(?:for the\b|for\b)\s*((?:\S+)(?:\s*receptor|\s*kinase|\s*receptors|\s*kinases)?)/ig;
            foreach my $m (@matches) {
              if (length($m)>2 and lc($m) ne 'the' and !grep(/^EXACT 42: \Q$m\E$/i, @abstract_matches)) {push @abstract_matches, "ABSTRACT FREE 42: " . $m;};
            }
            $found = 0;
          }
        }
        $found=0; undef %start_or_end;
        $abstract_text = $abstract->to_literal();
        if ($abstract_text =~/compounds that interact with .+/i) {
          my @count_matches = ($abstract_text =~/compounds that interact with (?:the\b)?\s*.+?/ig);
          my $count_matches = @count_matches;
          foreach my $syn (sort { length($b) <=> length($a) } keys %abstract_matches) {
            if (($abstract_text =~/compounds that interact with\s*(?:the\b)?\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/i) and $start_or_end{$-[0]}==0) {
              $start_or_end{$+[0]} = 1;
              my @count_matches_syn2 = ($abstract_text =~/compounds that interact with\s*(?:the)?\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig);
              my $count_matches_syn2 = @count_matches_syn2;
              for ( my $i = 1; $i < $count_matches_syn2 + 1; $i++ ) {
                my $append;
                if ($1 ne '') {
                  if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                    $append = 'receptor';
                  } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                    $append = 'kinase';
                  }
                  push @abstract_matches, "ABSTRACT EXACT 43: " .$syn . " $append";
                } else {
                  push @abstract_matches, "ABSTRACT EXACT 43: " .$syn;
                }
                $found = $found + $count_matches_syn2;
              }
            }
            if ($found == $count_matches) {
              last;
            }
          }
          if ($found <$count_matches) {
            my @matches = $abstract_text =~/compounds that interact with\s*(?:the\b)?\s*((?:\S+)(?:\s*receptor|\s*kinase|\s*receptors|\s*kinases)?)/ig;
            foreach my $m (@matches) {
              if (length($m)>2 and lc($m) ne 'the' and !grep(/^EXACT 43: \Q$m\E$/i, @abstract_matches)) {push @abstract_matches, "ABSTRACT FREE 43: " . $m;};
            }
            $found = 0;
          }
        }
        $found=0; undef %start_or_end;
        $abstract_text = $abstract->to_literal();
        if ($abstract_text =~/modulating the function of .+/i) {
          my @count_matches = ($abstract_text =~/modulating the function of\s*(?:a\b|an\b|the\b)?\b.+?/ig);
          my $count_matches = @count_matches;
          foreach my $syn (sort { length($b) <=> length($a) } keys %abstract_matches) {
            if (($abstract_text =~/modulating the function of\s*(?:a\b|an\b|the\b)?\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/i) and $start_or_end{$-[0]}==0) {
              $start_or_end{$+[0]} = 1;
              my @count_matches_syn2 = ($abstract_text =~/modulating the function of\s*(?:a\b|an\b|the\b)?\s*\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?/ig);
              my $count_matches_syn2 = @count_matches_syn2;
              for ( my $i = 1; $i < $count_matches_syn2 + 1; $i++ ) {
                my $append;
                if ($1 ne '') {
                  if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                    $append = 'receptor';
                  } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                    $append = 'kinase';
                  }
                  push @abstract_matches, "ABSTRACT EXACT 44: " .$syn . " $append";
                } else {
                  push @abstract_matches, "ABSTRACT EXACT 44: " .$syn;
                }
                $found = $found + $count_matches_syn2;
              }
            }
            if ($found == $count_matches) {
              last;
            }
          }
          if ($found <$count_matches) {
            my @matches = $abstract_text =~/modulating the function of (?:a\b|an\b|the\b)?\s*((?:\S+)(?:\s*receptor|\s*kinase|\s*receptors|\s*kinases)?)/ig;
            foreach my $m (@matches) {
              if (length($m)>2 and lc($m) ne 'the' and !grep(/^EXACT 44: \Q$m\E$/i, @abstract_matches)) {push @abstract_matches, "ABSTRACT FREE 44: " . $m;};
            }
            $found = 0;
          }
        }
        $found=0; undef %start_or_end;
        $abstract_text = $abstract->to_literal();
        if ($abstract_text =~/.+? ligand\b|ligands\b/i) {
          my @count_matches = ($abstract_text =~/.+? ligand\b|ligands\b/ig);
          my $count_matches = @count_matches;
          foreach my $syn (sort { length($b) <=> length($a) } keys %abstract_matches) {
            if (($abstract_text =~/\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*(?:ligand\b|ligands\b)/i) and $start_or_end{$+[0]}==0) {
              $start_or_end{$+[0]} = 1;
              my @count_matches_syn2 = ($abstract_text =~/\b\Q$syn\E\b\s*(receptor|kinase|receptors|kinases)?\s*(?:ligand\b|ligands\b)/ig);
              my $count_matches_syn2 = @count_matches_syn2;
              for ( my $i = 1; $i < $count_matches_syn2 + 1; $i++ ) {
                my $append;
                if ($1 ne '') {
                  if (lc($1) eq 'receptor' or lc($1) eq 'receptors') {
                    $append = 'receptor';
                  } elsif (lc($1) eq 'kinase' or lc($1) eq 'kinases') {
                    $append = 'kinase';
                  }
                  push @abstract_matches, "ABSTRACT EXACT 45: " .$syn . " $append";
                } else {
                  push @abstract_matches, "ABSTRACT EXACT 45: " .$syn;
                }
  
                $found = $found + $count_matches_syn2;
              }
            }
            if ($found == $count_matches) {
              last;
            }
          }
          if ($found <$count_matches) {
            my @matches = $abstract_text =~/((?:\S+)(?:\s*receptor|\s*kinase|\s*receptors|\s*kinases)?)\s*ligand|ligands\b/ig;
            foreach my $m (@matches) {
              if (length($m)>2 and lc($m) ne 'the' and !grep(/^EXACT 45: \Q$m\E$/i, @abstract_matches)) {push @abstract_matches, "ABSTRACT FREE 45: " . $m;};
            }
            $found = 0;
          }
        }
      }
  
      my @title_exact;
      my @title_free;
      my @abstract_exact;
      my @abstract_free;
      foreach my $t (@title_matches) {
        if ($t =~/TITLE EXACT \d+:/) {
          push @title_exact, $t;
        } elsif ($t =~/TITLE FREE \d+:/) {
          push @title_free, $t;
        }
      }
      foreach my $a (@abstract_matches) {
        if ($a =~/ABSTRACT EXACT \d+:/) {
          push @abstract_exact, $a;
        } elsif ($a =~/ABSTRACT FREE \d+:/) {
          push @abstract_free, $a;
        }
      }
      print RESULT $npat->to_literal() . "\n";
      if (scalar @title_exact > 0) {
        foreach my $e (@title_exact) {
          print RESULT "$e\n";
        }
      } elsif (scalar @title_exact == 0 and scalar @title_free > 0) {
        foreach my $f (@title_free) {
          print RESULT "$f\n";
        }
      } 
      if (scalar @abstract_exact > 0) {
        foreach my $e (@abstract_exact) {
          print RESULT "$e\n";
        }
      } elsif (scalar @abstract_exact == 0 and scalar @abstract_free > 0) {
        foreach my $f (@abstract_free) {
          print RESULT "$f\n";
        }
      }
      @exact = ();
      @free = ();
    }
  }
}
