package Fastadb::App::Controller::Batchseq;

use Mojo::Base 'Mojolicious::Controller';

sub batch {
	my ($self) = @_;
	my $ids = $self->every_param('id');

  my @results;
  foreach my $id (@{$ids}) {
    my $r = { id => $id, found => 0 };
    my $seq = $self->db()->resultset('Seq')->get_seq($id);
    if($seq) {
      $r->{found} = 1;
      $r->{sha1} = $seq->sha1();
      $r->{seq} = $seq->get_seq();
    }
    push(@results, $r);
  }

  $self->respond_to(
    json => { json => \@results },
    any => { data => 'Unsupported Media Type', status => 415 }
  );
}

1;