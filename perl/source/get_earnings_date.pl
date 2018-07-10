#!/usr/bin/perl
use LWP::Simple;
my (%tickhash,%datehash,$str,$ticker,$prev_day,$cname);
($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
$mon += 1;
$year += 1900;
$today = sprintf("%04d%02d%02d",$year,$mon,$mday);
my $todaydb = sprintf("%04d\-%02d\-%02d",$year,$mon,$mday);
open (F,"<usticker.lst");
while(<F>)
{
  chomp;
  $tickhash{$_}++;
} 
close (F);
#first get update date
my ($updown,$upgradeurl,$downgradeurl);
use Date::Calc qw(Add_Delta_Days Day_of_Week);
my $entered_date = $todaydb;
my $days = 0;
while ($days < 2)
{
($year,$mon,$mday) = Add_Delta_Days(split(/-/,$entered_date),$days);
$dow = Day_of_Week($year,$mon,$mday);
$today = sprintf("%04d%02d%02d",$year,$mon,$mday);
$todaydb = sprintf("%04d\-%02d\-%02d",$year,$mon,$mday);
if ($dow =~ /^[1|2|3|4|5]$/)
{
$url ='http://biz.yahoo.com/research/earncal/'.$today.'.html';
$content = get ($url);
$content =~ s/\n/ /g;
if ($content =~ /^.*?Calendar<\/b><\/font>(.*?)<\/table>/)
{
$str = $1;
($year,$mon,$mday) = Add_Delta_Days(split(/-/,$todaydb),-10);
$prev_day = sprintf("%04d\-%02d\-%02d",$year,$mon,$mday);

while ($str =~ /.*?bgcolor=eeeeee><td>(.*?)<\/td><td>.*?href.*?>(.*?)<.*?<\/td>/gs)
{
$cname = $1;
$ticker = $2;
if ($ticker eq 'Add'){next};
          if ($tickhash{$ticker})
            {
              $ins_query = "$ticker,$cname,$todaydb"; 
            }
            else
            {
              $ins_query = ''; 
            }
            if ($ins_query)
            {  
             $ins_query =~ s/\&amp\;/\&/g;
             print "$ins_query\n";
             print OUT "$row[0],$row[1]\n";
            }
}
}
}
$days++;
}
use MIME::Lite;
my ($d,$m,$y) = (localtime)[3,4,5];
my $str = sprintf '%04d-%02d-%02d', $y+1900,$m+1,$d;
my $file = "/home/tthaliath/tickerlick/daily/earnings/earnings-".$str."\.csv";
open(OUT,">$file");
print OUT "$row[0],$row[1]\n";
close (OUT);
my $msg = MIME::Lite->new(
    From    => 'tthaliath@gmail.com',
    To      => 'tthaliath@gmail.com',
    Subject => 'daily earnings report (Today/Next Day)',
    Type    => 'multipart/mixed',
);
my $Mail_msg = "$str\n\n";
$Mail_msg .= "Tickerlick - Earnings Today/Next Day\n\n";
open (F,"<$file");
undef $/;
$Mail_msg .= <F>;
close (F);
$/ = 1;
close (F);
### Add the text message part
 $msg->attach (
  Type => 'TEXT',
   Data => $Mail_msg
   ) or die "Error adding the text message part: $!\n";

$msg->send;
1;

