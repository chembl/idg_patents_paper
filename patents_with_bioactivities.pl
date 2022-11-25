#!/usr/bin/perl
use strict;
use POSIX;
use XML::LibXML;
use Encode;

$ENV{'NLS_LANG'} = 'AMERICAN_AMERICA.AL32UTF8';
my $file_index = $ARGV[0];
$| = 1;

open(OUTPUT, ">:utf8","bioactivities_$file_index");
print OUTPUT "--------------------------------------------------------\n";

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

while (my $filename = readdir LASTUPD) {
  if (!exists $pat_list{$filename}) {next;}
  my $dom = XML::LibXML->load_xml(location => "$dir/$filename");
  foreach my $npat ($dom->findnodes('/patent-document/@ucid')) {
    foreach my $entry ($npat->findnodes("//tables/table//entry")) {
      my $table_title = $entry->findnodes("ancestor::table/title/descendant-or-self::title");
      my $table_id = $entry->findnodes("ancestor::tables/attribute::id");
      my $table_header = $entry->findnodes("(ancestor::table//thead/row/entry/descendant-or-self::entry)[1]");
      if ($entry=~m/\b\QIC50\E\b/i or $entry=~m/\b\QXC50\E\b/i or $entry=~m/\b\QEC50\E\b/i or $entry=~m/\b\QAC50\E\b/i or ($entry=~m/\b\QKi\E\b/i and $entry!~m/\b\QKi-\E\b/i) 
or ($entry=~m/\b\QKd\E\b/i and $entry!~m/\b\QkD\E\b/) or $entry=~m/\b\QpIC50\E\b/i or $entry=~m/\b\QpXC50\E\b/i or $$entry=~m/\b\QpEC50\E\b/i or $entry=~m/\b\QpAC50\E\b/i
or $entry=~m/\b\Q-log(IC50)\E\b/i or $entry=~m/\b\Q-log(XC50)\E\b/i or $entry=~m/\b\Q-log(EC50)\E\b/i or $entry=~m/\b\Q-log(AC50)\E\b/i
or $entry=~m/\b\Qconcentration to inhibit\E\b/i
or $entry=~m/\b\QIC-50\E\b/i or $entry=~m/\b\QXC-50\E\b/i or $entry=~m/\b\QEC-50\E\b/i or $entry=~m/\b\QAC-50\E\b/i
or $entry=~m/\b\QIC 50\E\b/i or $entry=~m/\b\QXC 50\E\b/i or $entry=~m/\b\QEC 50\E\b/i or $entry=~m/\b\QAC 50\E\b/i) {
        print OUTPUT $npat->to_literal() . "\nTable id: $table_id\nTable title: " . $table_title->to_literal() . "\nTable header: " . $table_header->to_literal() . "\n" . $entry->to_literal() . "\n--------------------------------------------------------\n";

      } elsif ($entry=~m/\b\QIC\E\b/i or $entry=~m/\b\QEC\E\b/i or $entry=~m/\b\QXC\E\b/i or $entry=~m/\b\QAC\E\b/i or $entry=~m/\b\QpIC\E\b/i or $entry=~m/\b\QpEC\E\b/i or $entry=~m/\b\QpXC\E\b/i or $entry=~m/\b\QpAC\E\b/i) {
        foreach my $sub ($entry->findnodes(".//sub/text()")) {
          if ($sub=~m/\b\Q50\E\b/i) {
            print OUTPUT $npat->to_literal() . "\nTable id: $table_id\nTable title: " . $table_title->to_literal() . "\nTable header: " . $table_header->to_literal() . "\n" . $entry->to_literal() . "\n--------------------------------------------------------\n";
          }
        }
      } elsif ($entry=~m/\b\QK\E\b/i) {
        foreach my $sub2 ($entry->findnodes(".//sub/text()")) {
          if ($sub2=~m/\b\Qi\E\b/i or $sub2=~m/\b\Qd\E\b/i) {
            print OUTPUT $npat->to_literal() . "\nTable id: $table_id\nTable title: " . $table_title->to_literal() . "\nTable header: " . $table_header->to_literal() . "\n" . $entry->to_literal() . "\n--------------------------------------------------------\n";
          }
        }
      }
    }
  }
}
