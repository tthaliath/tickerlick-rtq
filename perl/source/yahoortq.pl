#!/usr/bin/perl

use lib qw(/home/tickerlick/cgi-bin);
use LWP::Simple;
use DBI;
use POSIX qw(strftime);
my $price_date = $ARGV[0];
my $max = $ARGV[1];
my ($ord_id,$now,$dbh,@row,$sth,$sql,$tickerlist,%tickhash,$tick,$quote,$prev_date,$prev_prev_date);
sleep(15);
my $dbh = DBI->connect('dbi:mysql:tickmaster','root','Neha*2005')
 or die "Connection Error: $DBI::errstr\n";
$prev_query ="select max(price_date) from tickerrtq5 where ticker_id = 9 and price_date < '$price_date' ";
$sth_date = $dbh->prepare($prev_query);
 $sth_date->execute or die "SQL Error: $DBI::errstr\n";
 #print "$query\n";
 while (@row = $sth_date->fetchrow_array) {
 $prev_date = $row[0];
 }
$sth_date->finish();
$prev_query ="select max(price_date) from tickerrtq5 where ticker_id = 9 and price_date < '$prev_date' ";
$sth_date = $dbh->prepare($prev_query);
 $sth_date->execute or die "SQL Error: $DBI::errstr\n";
 #print "$query\n";
 while (@row = $sth_date->fetchrow_array) {
  $prev_prev_date = $row[0];
   }
   $sth_date->finish();
my $mktclose = 0;
#print "start:$now\n";
my $ins_query = "insert into tickerrtq5 (ticker_id,price_date,rtq) values (?,?,?)";
$in_sth = $dbh->prepare($ins_query);
$sql = "select  ticker,ticker_id  from rtq_proc_master where proc_ord_id = ?";

my $sth = $dbh->prepare($sql);
while ($mktclose == 0)
{
$ord_id = $max - 9;
if ($max == 78 ){$ord_id = 71;}
while ($ord_id <= $max)
{
$tickerlist ='';
$sth->execute($ord_id) or die "SQL Error: $DBI::errstr\n";
while (@row = $sth->fetchrow_array)
{
   $tickerlist .= $row[0].',';
   $tickhash{$row[0]} = $row[1];
}
#$tickerlist .= 'SPY';
#$tickhash{'SPY'} = 10909;
$tickerlist =~ s/\,$//;

#print "$tickerlist\n";
&getResults("$tickerlist");
#print "$ord_id\n";
$ord_id++;
}
$now = strftime "%H", localtime;
if ($now == 13){$mktclose = 1;}
$ord_id = $max - 9;
if ($max == 78 ){$ord_id = 71;}
while ($ord_id <= $max)
{
system("/home/tthaliath/tickerlick/history/rtq/daily/update_dma_rtq_daily_1.pl $ord_id $prev_date $prev_prev_date");
system("/home/tthaliath/tickerlick/history/rtq/daily/update_loss_gain_rtq_daily_2.pl $ord_id $price_date");
system("/home/tthaliath/tickerlick/history/rtq/daily/update_ema_535_rtq_daily_3.pl $ord_id  $price_date $prev_date");
system("/home/tthaliath/tickerlick/history/rtq/daily/update_avg_loss_gain_daily_5.pl $ord_id $prev_date");
$ord_id++;
}
sleep(135);
}
$sth->finish;
$now = strftime "%H%M%S", localtime;
#print "finish:$now\n";
sub getResults
{
my ($ticker) = uc shift;
#$url = "http://finance.yahoo.com/q?s=$ticker&ql=1";
#$url = "http://finance.yahoo.com/quotes/$ticker/view/e";
$url = "http://finance.yahoo.com/quotes/$ticker/view/e?bypass=true&ltr=1";
# "id": "22144" ,"t" : "AAPL" ,"e" : "NASDAQ" ,"l" : "130.07" ,"l_fix" : "130.07" ,"l_cur" : "130.07"
#print "$url\n";
my $rtqstr = get ($url);
$rtqstr =~ s/\n/ /g;
#print "$rtqstr\n";
#id="yfs_l84_amzn">431.63</span>
while ($rtqstr =~ /.*?id\=\"yfs_l84_(.*?)\">(.*?)<\/span>/g)
{
   #print "$1,$2\n";
     $tick = uc $1;
    $quote = $2;
    $quote =~ s/\,//g;
    #print "$tick,$quote\n";
    $in_sth->execute($tickhash{$tick},$price_date,$quote);
}
}
$in_sth->finish;
$dbh-disconnect;
1;
