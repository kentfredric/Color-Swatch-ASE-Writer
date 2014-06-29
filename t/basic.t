use strict;
use warnings;

use Test::More;
use Test::Differences;

# ABSTRACT: Basic test

use Color::Swatch::ASE::Writer;

subtest "No blocks" => sub {
  my $structure = {
    signature => 'ASEF',
    version   => [ 1, 0 ],
    blocks    => []
  };

  my $out = Color::Swatch::ASE::Writer->write_string($structure);

  my $expected = 'ASEF';
  $expected .= "\x{00}\x{01}\x{00}\x{00}";    # version
  $expected .= "\x{00}\x{00}\x{00}\x{00}";    # num blocks

  my (@chunks)  = grep length, split /(.{0,4})/, $out;
  my (@echunks) = grep length, split /(.{0,4})/, $expected;

  eq_or_diff \@chunks, \@chunks;
};

subtest "Start" => sub {
  my $structure = {
    signature => 'ASEF',
    version   => [ 1, 0 ],
    blocks    => [ { type => 'group_start' }, ]
  };

  my $out      = Color::Swatch::ASE::Writer->write_string($structure);
  my $expected = 'ASEF';
  $expected .= "\x{00}\x{01}\x{00}\x{00}";    # version
  $expected .= "\x{00}\x{00}\x{00}\x{01}";    # numblocks
                                              # block 1
  $expected .= "\x{c0}\x{01}";                # group start
  $expected .= "\x{00}\x{00}\x{00}\x{04}";    # block length = 4
  $expected .= "\x{00}\x{0d}";                # block group = 13
  $expected .= "\x{00}\x{00}";                # label is only a null terminator.

  my (@chunks) = grep length, split /(.{0,4})/, $out;

  my (@echunks) = grep length, split /(.{0,4})/, $expected;

  eq_or_diff \@chunks, \@echunks;
};

subtest "Start Labelled" => sub {
  my $structure = {
    signature => 'ASEF',
    version   => [ 1, 0 ],
    blocks    => [
      {
        type  => 'group_start',
        label => "Various",
      },
    ]
  };

  my $out      = Color::Swatch::ASE::Writer->write_string($structure);
  my $expected = 'ASEF';
  $expected .= "\x{00}\x{01}\x{00}\x{00}";                            # version
  $expected .= "\x{00}\x{00}\x{00}\x{01}";                            # numblocks
                                                                      # block 1
  $expected .= "\x{c0}\x{01}";                                        # group start
  $expected .= "\x{00}\x{00}\x{00}\x{12}";                            # block length = 18
  $expected .= "\x{00}\x{0d}";                                        # block group = 13
  $expected .= "\x{00}\x{56}\x{00}\x{61}\x{00}\x{72}\x{00}\x{69}";    # "Vari" in UTF16-BE
  $expected .= "\x{00}\x{6f}\x{00}\x{75}\x{00}\x{73}";                # "ous" in UTF16-BE
  $expected .= "\x{00}\x{00}";                                        # label null terminator.

  my (@chunks)  = grep length, split /(.{0,4})/, $out;
  my (@echunks) = grep length, split /(.{0,4})/, $expected;

  eq_or_diff \@chunks, \@echunks;
};
subtest "Start Labelled w/block group" => sub {
  my $structure = {
    signature => 'ASEF',
    version   => [ 1, 0 ],
    blocks    => [
      {
        type  => 'group_start',
        label => "Various",
        group => 32,
      },
    ]
  };

  my $out      = Color::Swatch::ASE::Writer->write_string($structure);
  my $expected = 'ASEF';
  $expected .= "\x{00}\x{01}\x{00}\x{00}";                            # version
  $expected .= "\x{00}\x{00}\x{00}\x{01}";                            # numblocks
                                                                      # block 1
  $expected .= "\x{c0}\x{01}";                                        # group start
  $expected .= "\x{00}\x{00}\x{00}\x{12}";                            # block length = 18
  $expected .= "\x{00}\x{20}";                                        # block group = 32
  $expected .= "\x{00}\x{56}\x{00}\x{61}\x{00}\x{72}\x{00}\x{69}";    # "Vari" in UTF16-BE
  $expected .= "\x{00}\x{6f}\x{00}\x{75}\x{00}\x{73}";                # "ous" in UTF16-BE
  $expected .= "\x{00}\x{00}";                                        # label null terminator.

  my (@chunks)  = grep length, split /(.{0,4})/, $out;
  my (@echunks) = grep length, split /(.{0,4})/, $expected;

  eq_or_diff \@chunks, \@echunks;
};

subtest "Start + End" => sub {
  my $structure = {
    signature => 'ASEF',
    version   => [ 1, 0 ],
    blocks    => [
      {
        type  => 'group_start',
        label => "Various",
        group => 32,
      },
      {
        type => 'group_end',
      },
    ]
  };

  my $out      = Color::Swatch::ASE::Writer->write_string($structure);
  my $expected = 'ASEF';
  $expected .= "\x{00}\x{01}\x{00}\x{00}";                            # version
  $expected .= "\x{00}\x{00}\x{00}\x{02}";                            # numblocks
                                                                      # block 1
  $expected .= "\x{c0}\x{01}";                                        # group start
  $expected .= "\x{00}\x{00}\x{00}\x{12}";                            # block length = 18
  $expected .= "\x{00}\x{20}";                                        # block group = 32
  $expected .= "\x{00}\x{56}\x{00}\x{61}\x{00}\x{72}\x{00}\x{69}";    # "Vari" in UTF16-BE
  $expected .= "\x{00}\x{6f}\x{00}\x{75}\x{00}\x{73}";                # "ous" in UTF16-BE
  $expected .= "\x{00}\x{00}";                                        # label null terminator.

  #---------------- block 2
  $expected .= "\x{c0}\x{02}";                                        # group end
  $expected .= "\x{00}\x{00}\x{00}\x{00}";                            # block length = 0

  my (@chunks)  = grep length, split /(.{0,4})/, $out;
  my (@echunks) = grep length, split /(.{0,4})/, $expected;

  eq_or_diff \@chunks, \@echunks;
};

subtest "Start + Color + End" => sub {
  my $structure = {
    signature => 'ASEF',
    version   => [ 1, 0 ],
    blocks    => [
      {
        type  => 'group_start',
        label => "Various",
        group => 32,
      },
      {
        type   => "color",
        model  => 'RGB ',
        values => [ 0.9, 0.8, 0.7 ]
      },
      {
        type => 'group_end',
      },
    ]
  };

  my $out      = Color::Swatch::ASE::Writer->write_string($structure);
  my $expected = 'ASEF';
  $expected .= "\x{00}\x{01}\x{00}\x{00}";    # version
  $expected .= "\x{00}\x{00}\x{00}\x{03}";    # numblocks

  #------- block 1
  $expected .= "\x{c0}\x{01}";                                        # group start
  $expected .= "\x{00}\x{00}\x{00}\x{12}";                            # block length = 18
  $expected .= "\x{00}\x{20}";                                        # block group = 32
  $expected .= "\x{00}\x{56}\x{00}\x{61}\x{00}\x{72}\x{00}\x{69}";    # "Vari" in UTF16-BE
  $expected .= "\x{00}\x{6f}\x{00}\x{75}\x{00}\x{73}";                # "ous" in UTF16-BE
  $expected .= "\x{00}\x{00}";                                        # label null terminator.

  #-------- block 2

  $expected .= "\x{00}\x{01}";                                        # color
  $expected .= "\x{00}\x{00}\x{00}\x{16}";                            # block length = 22
  $expected .= "\x{00}\x{01}";                                        # block group = 1
  $expected .= "\x{00}\x{00}";                                        # label null terminator
  $expected .= "RGB\x{20}";                                           # colour model

  $expected .= "\x{3f}\x{66}\x{66}\x{66}";                            # 0.9 as a float ( red )
  $expected .= "\x{3f}\x{4c}\x{cc}\x{cd}";                            # 0.8 as a float ( green )
  $expected .= "\x{3f}\x{33}\x{33}\x{33}";                            # 0.7 as a float ( blue )
  $expected .= "\x{00}\x{02}";                                        # colour type

  #---------------- block 3
  $expected .= "\x{c0}\x{02}";                                        # group end
  $expected .= "\x{00}\x{00}\x{00}\x{00}";                            # block length = 0

  my (@chunks)  = grep length, split /(.{0,4})/, $out;
  my (@echunks) = grep length, split /(.{0,4})/, $expected;

  eq_or_diff \@chunks, \@echunks;
};

subtest "Start + Color CMYK + End" => sub {
  my $structure = {
    signature => 'ASEF',
    version   => [ 1, 0 ],
    blocks    => [
      {
        type  => 'group_start',
        label => "Various",
        group => 32,
      },
      {
        type   => "color",
        model  => 'CMYK',
        values => [ 0.9, 0.8, 0.7, 0.6 ]
      },
      {
        type => 'group_end',
      },
    ]
  };

  my $out      = Color::Swatch::ASE::Writer->write_string($structure);
  my $expected = 'ASEF';
  $expected .= "\x{00}\x{01}\x{00}\x{00}";    # version
  $expected .= "\x{00}\x{00}\x{00}\x{03}";    # numblocks

  #------- block 1
  $expected .= "\x{c0}\x{01}";                                        # group start
  $expected .= "\x{00}\x{00}\x{00}\x{12}";                            # block length = 18
  $expected .= "\x{00}\x{20}";                                        # block group = 32
  $expected .= "\x{00}\x{56}\x{00}\x{61}\x{00}\x{72}\x{00}\x{69}";    # "Vari" in UTF16-BE
  $expected .= "\x{00}\x{6f}\x{00}\x{75}\x{00}\x{73}";                # "ous" in UTF16-BE
  $expected .= "\x{00}\x{00}";                                        # label null terminator.

  #-------- block 2

  $expected .= "\x{00}\x{01}";                                        # color
  $expected .= "\x{00}\x{00}\x{00}\x{1A}";                            # block length = 26
  $expected .= "\x{00}\x{01}";                                        # block group = 1
  $expected .= "\x{00}\x{00}";                                        # label null terminator
  $expected .= "CMYK";                                                # colour model

  $expected .= "\x{3f}\x{66}\x{66}\x{66}";                            # 0.9 as a float ( c )
  $expected .= "\x{3f}\x{4c}\x{cc}\x{cd}";                            # 0.8 as a float ( m )
  $expected .= "\x{3f}\x{33}\x{33}\x{33}";                            # 0.7 as a float ( y )
  $expected .= "\x{3f}\x{19}\x{99}\x{9a}";                            # 0.6 as a float ( k )

  $expected .= "\x{00}\x{02}";                                        # colour type

  #---------------- block 3
  $expected .= "\x{c0}\x{02}";                                        # group end
  $expected .= "\x{00}\x{00}\x{00}\x{00}";                            # block length = 0

  my (@chunks)  = grep length, split /(.{0,4})/, $out;
  my (@echunks) = grep length, split /(.{0,4})/, $expected;

  eq_or_diff \@chunks, \@echunks;
};
done_testing;

