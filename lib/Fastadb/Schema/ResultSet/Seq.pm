package Fastadb::Schema::ResultSet::Seq;

use strict;
use warnings;

use base qw/DBIx::Class::ResultSet/;
use Digest::SHA qw(sha1_hex);

sub create_seq {
  my ($self, $seq_hash, $seq_type_obj, $release_obj) = @_;
  my $hash = sha1_hex($seq_hash->{sequence});
  my $seq_obj = $self->find_or_new({seq => $seq_hash->{sequence}, sha1 => $hash, seq_type => $seq_type_obj},{key => 'seq_sha1_uniq'});
  my $first_seen = 0;
  if(!$seq_obj->in_storage()) {
    $first_seen = 1;
    $seq_obj->insert();
  }
  #TODO get the write working here (now a many to many relationship)
  my $molecule_obj = $seq_obj->find_or_create_related(
    'molecules',
    {
      stable_id => $seq_hash->{id},
      first_seen => $first_seen,
      release => $release_obj,
    }
  );
  return $molecule_obj;
}

sub get_seq {
  my ($self, $id, $checksum_algorithm) = @_;
  $checksum_algorithm //= $self->detect_algorithm($id);
  return undef unless $self->allowed_algorithm($checksum_algorithm);
  return $self->find({
    $checksum_algorithm => $id
  },
  {
    prefetch => {'molecule_seqs' => 'molecule'}
  });
}

sub detect_algorithm {
  my ($self, $key) = @_;
  my $length = length($key);
  my $checksum_column = ($length == 32) ? 'md5'
                      : ($length == 40) ? 'sha1'
                      : ($length == 64) ? 'sha256'
                      : undef;
  return $checksum_column;
}

my %algorithms = map {$_ => 1} qw/md5 sha1 sha256/;
sub allowed_algorithm {
  my ($self, $key) = @_;
  return 0 unless defined $key;
  return exists $algorithms{$key};
}

1;