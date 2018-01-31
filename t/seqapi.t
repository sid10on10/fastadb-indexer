use Test::More;

use strict;
use warnings;

use Test::DBIx::Class {
  schema_class => 'Fastadb::Schema',
  resultsets => [ qw/Seq SeqType Release Molecule MoleculeSeq Division Species/ ],
};
use Test::Mojo;

isa_ok Schema, 'Fastadb::Schema'=> 'Got Correct Schema';
isa_ok ResultSet('Seq'), 'Fastadb::Schema::ResultSet::Seq'=> 'Got the right Seq';

my ($type, $division, $species, $release);
fixtures_ok sub {
	$type = SeqType->create({seq_type => 'protein'});
	$division = Division->create({division => 'ensembl'});
	$species = Species->create({species => 'yeast'});
	$release = Release->create({release => 91, species => $species, division => $division});
};

fixtures_ok sub {
  my $seq = Seq->create({
    seq => 'MFSELINFQNEGHECQCQCGSCKNNEQCQKSCSCPTGCNSDDKCPCGNKSEETKKSCCSGK',
    md5 => 'b6517aa110cc10776af5c368c5342f95',
    sha1 => '2db01e3048c926193f525e295662a901b274a461',
    sha256 => '118fc0d17e5eee7e0b98f770844fade5a717e8a78d86cf8b1f81a13ffdbd269b',
    size => 61,
    seq_type => $type,
  });
  my $seq2 = Seq->create({
    seq => 'MSSPTPPGGQRTLQKRKQGSSQKVAASAPKKNTNSNNSILKIYSDEATGLRVDPLVVLFLAVGFIFSVVALHVISKVAGKLF',
    md5 => 'c8e76de5f86131da26e8dd163658290d',
    sha1 => 'f5c6270cf86632900e741d865794f18a4ce98c8d',
    sha256 => '22e3e2203700e0b0879ed8b350febc086de4420b6e843d17e8d5e3a11461ae0f',
    size => 82,
    seq_type => $type,
  });

  my $mol1 = Molecule->create({
    stable_id => 'YHR055C',
    first_seen => 1,
    release => $release,
  });
  MoleculeSeq->create({seq => $seq, molecule => $mol1});

  my $mol2 = Molecule->create({
    stable_id => 'YER087C-B',
    first_seen => 1,
    release => $release,
  });
  MoleculeSeq->create({seq => $seq2, molecule => $mol2});

},'Installed fixtures';

# Set the application with the right schema. SQLite memory databases are a per driver thing
my $t = Test::Mojo->new('Fastadb::App');
$t->app->schema(Schema);

my $md5 = 'b6517aa110cc10776af5c368c5342f95';
my $seq_obj = Seq->get_seq($md5, 'md5');
my $raw_seq = $seq_obj->seq();
foreach my $m (qw/md5 sha1 sha256/) {
  $t->get_ok('/sequence/'.$seq_obj->$m() => { Accept => 'text/plain'})
    ->status_is(200)
    ->content_is($raw_seq);
}

# Trying Range request because we do not support this
my $basic_url = '/sequence/'.$md5;
$t->get_ok($basic_url => { Accept => 'text/plain', Range => 'bytes=0-10'})
  ->status_is(416)
  ->content_is('Range Not Satisfiable');

# Good substring request
$t->get_ok("/sequence/${md5}?start=0&end=1" => { Accept => 'text/plain' })
  ->status_is(200)
  ->content_is('M');

# Substring with start but no end
$t->get_ok("/sequence/${md5}?start=58" => { Accept => 'text/plain' })
  ->status_is(200)
  ->content_is('SGK');

# Bad start/end request
$t->get_ok("/sequence/${md5}?start=10&end=1" => { Accept => 'text/plain' })
  ->status_is(416)
  ->content_is('Range Not Satisfiable');

# Bad start/end request
$t->get_ok("/sequence/${md5}?start=1000" => { Accept => 'text/plain' })
  ->status_is(400)
  ->content_is('Invalid Range');

# Bad formats
$t->get_ok($basic_url => { Accept => 'text/html' })
  ->status_is(415)
  ->content_is('Unsupported Media Type');

# FASTA now
$t->get_ok($basic_url => { Accept => 'text/x-fasta' })
  ->status_is(200)
  ->content_is(">2db01e3048c926193f525e295662a901b274a461
MFSELINFQNEGHECQCQCGSCKNNEQCQKSCSCPTGCNSDDKCPCGNKSEETKKSCCSG
K");

# Trying head requests now
$t->head_ok($basic_url => { Accept => 'text/plain'})
  ->status_is(200)
  ->content_type_is('text/plain;charset=UTF-8')
  ->header_is('Content-Length', '61');

$t->get_ok('/sequence/bogus' => { Accept => 'text/plain'})
  ->status_is(404)
  ->content_is('Not Found');

my $stable_id = 'YER087C-B';
my $mol = Molecule->find({ stable_id => $stable_id}, { join => {molecule_seqs => 'seq'}});
my $seqs = [$mol->seqs->all];
my $seq_local = $seqs->[0];
$t->get_ok('/metadata/'.$seq_local->sha1 => { Accept => 'application/json'})
	->status_is(200)
  ->json_is({
    metadata => {
      id => $seq_local->sha1,
      length => 82,
      aliases => [
        { alias => $seq_local->md5},
        { alias => $seq_local->sha1 },
        { alias => $seq_local->sha256 },
        { alias => $stable_id },
      ]
    }
  })->or(sub { diag explain $t->tx->res->json });

done_testing();
