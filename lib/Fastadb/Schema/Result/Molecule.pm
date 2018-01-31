package Fastadb::Schema::Result::Molecule;

use strict;
use warnings;

use base 'DBIx::Class::Core';
use Class::Method::Modifiers;

__PACKAGE__->table('molecule');

__PACKAGE__->add_columns(
	molecule_id =>{
		data_type => 'integer',
		size      => 16,
		is_nullable => 0,
		is_auto_increment => 1,
    is_numeric => 1,
	},
	release_id =>{
		data_type => 'integer',
		size      => 16,
		is_nullable => 0,
		is_numeric => 1,
  },
	stable_id =>{
		data_type => 'varchar',
    size => 128,
		is_nullable => 0,
	},
	first_seen  =>{
		data_type   => 'integer',
    is_boolean  => 1,
		false_is    => ['0','-1'],
		is_nullable => 0,
	},
	version =>{
		data_type => 'integer',
		size      => 4,
		is_nullable => 1,
    is_numeric => 1,
	},
);

__PACKAGE__->add_unique_constraint(
  molecule_uniq => [qw/stable_id/]
);

__PACKAGE__->set_primary_key('molecule_id');

__PACKAGE__->belongs_to(release => 'Fastadb::Schema::Result::Release', 'release_id');

__PACKAGE__->has_many(
  "molecule_seqs" => "Fastadb::Schema::Result::MoleculeSeq",
	'seq_id',
  { "foreign.molecule_id" => "self.molecule_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->many_to_many('seqs', 'molecule_seqs', 'seq');

1;