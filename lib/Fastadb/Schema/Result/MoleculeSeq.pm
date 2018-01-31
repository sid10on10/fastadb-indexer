package Fastadb::Schema::Result::MoleculeSeq;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("molecule_seq");

__PACKAGE__->add_columns(
  molecule_id =>{
		data_type => 'integer',
		size      => 16,
		is_nullable => 0,
		is_auto_increment => 1,
    is_numeric => 1,
	},
  seq_id =>{
		data_type => 'integer',
		size      => 16,
		is_nullable => 0,
		is_auto_increment => 1,
    is_numeric => 1,
	},
);

__PACKAGE__->belongs_to("molecule",
  "Fastadb::Schema::Result::Molecule",
  { molecule_id => "molecule_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

__PACKAGE__->belongs_to("seq",
  "Fastadb::Schema::Result::Seq",
  { seq_id => "seq_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

1;
