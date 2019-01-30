# Copyright 2015 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets 
# the needs in IT infrastructure and application monitoring for 
# service performance.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0  
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

package centreon::vmware::cmddatastoreusage;

use base qw(centreon::vmware::cmdbase);

use strict;
use warnings;
use centreon::vmware::common;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(%options);
    bless $self, $class;
    
    $self->{commandName} = 'datastoreusage';
    
    return $self;
}

sub checkArgs {
    my ($self, %options) = @_;

    if (defined($options{arguments}->{datastore_name}) && $options{arguments}->{datastore_name} eq "") {
        centreon::vmware::common::set_response(code => 100, short_message => "Argument error: datastore name cannot be null");
        return 1;
    }
 
    return 0;
}

sub run {
    my $self = shift;

    my $multiple = 0;
    my $filters = $self->build_filter(label => 'name', search_option => 'datastore_name', is_regexp => 'filter');
    my @properties = ('summary');

    my $result = centreon::vmware::common::search_entities(command => $self, view_type => 'Datastore', properties => \@properties, filter => $filters);
    return if (!defined($result));
    
    my $data = {};
    foreach my $entity_view (@$result) {
        my $entity_value = $entity_view->{mo_ref}->{value};
        
        $data->{$entity_value} = { name => $entity_view->summary->name, state => $entity_view->summary->accessible };
        next if (centreon::vmware::common::is_accessible(accessible => $entity_view->summary->accessible) == 0);
        
        # capacity 0...
        if ($entity_view->summary->capacity <= 0) {
            $data->{$entity_value}->{size} = 0;
            next;
        }
        
        # in Bytes
        $data->{$entity_value}->{size} = $entity_view->summary->capacity;
        $data->{$entity_value}->{free} = $entity_view->summary->freeSpace;
        
        my ($total_uncommited, $prct_uncommited);
        my $msg_uncommited = '';
        if (defined($entity_view->summary->uncommitted)) {
            $data->{$entity_value}->{uncommitted} = $entity_view->summary->uncommitted;  
        }
    }
    
    centreon::vmware::common::set_response(data => $data);
}

1;
