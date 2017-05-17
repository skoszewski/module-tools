# --
# Copyright (C) 2001-2017 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Console::Command::Module::Code::Upgrade;

use strict;
use warnings;

use File::Spec();

use parent qw(Console::BaseCommand Console::BaseModule);

=head1 NAME

Console::Command::Module::Code::Upgrade - Console command to execute the <CodeUpgrade> section of a module.

=head1 DESCRIPTION

Runs code upgrade part from a module .sopm file.

=cut

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description('Run code upgrade from a module .sopm file.');
    $Self->AddArgument(
        Name        => 'module-file-path',
        Description => "Specify a module .sopm file.",
        Required    => 1,
        ValueRegex  => qr/.*/smx,
    );

    $Self->AddArgument(
        Name        => 'version',
        Description => "Specify a version of the CodeUpgrade to run.",
        Required    => 0,
        ValueRegex  => qr/^\d+\.\d+\.\d+$/smx,
    );

    return;
}

sub PreRun {
    my ($Self) = @_;

    eval { require Kernel::Config };
    if ($@) {
        die "This console command needs to be run from a framework root directory!";
    }

    my $Module = $Self->GetArgument('module-file-path');

    # Check if .sopm file exists.
    if ( !-e "$Module" ) {
        die "Can not find file $Module!\n";
    }

    return;
}

sub Run {
    my ($Self) = @_;

    $Self->Print("<yellow>Running module code install...</yellow>\n\n");

    my $Module = File::Spec->rel2abs( $Self->GetArgument('module-file-path') );

    # To capture the standard error.
    my $ErrorMessage = '';

    my $Success;

    {
        # Localize the standard error, everything will be restored after the block.
        local *STDERR;

        # Redirect the standard error to a variable.
        open STDERR, ">>", \$ErrorMessage;

        $Success = $Self->CodeActionHandler(
            Module  => $Module,
            Action  => 'Upgrade',
            Version => $Self->GetArgument('version') // '',
        );
    }

    $Self->Print("$ErrorMessage\n");

    if ( !$Success || $ErrorMessage =~ m{error}i ) {
        $Self->PrintError("Couldn't run code install correctly from $Module");
        return $Self->ExitCodeError();
    }

    $Self->Print("\n<green>Done.</green>\n");
    return $Self->ExitCodeOk();
}

1;

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<http://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
