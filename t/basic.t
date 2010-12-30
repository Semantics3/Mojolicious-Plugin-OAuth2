use Test::More;
use Mojolicious::Lite;
use Test::Mojo;
use Test::More;


plugin 'o_auth2', test => {
    authorize_url => ('/fake_auth'),
    token_url => ('/fake_token'),
    key    => 'fake_key',
    secret => 'fake_secret',
};

get '/oauth' => sub { 
    my $self=shift;
    if(my $token=$self->get_token('test')) {
        
        $self->render(text=>'Token '.$token);
    }
};

get 'fake_auth' => sub {
    my $self=shift;
    if ($self->param('client_id') && $self->param('redirect_uri')) {
        my $return=Mojo::URL->new($self->param('redirect_uri'));
        $return->query->append(code=>'fake_code');
        $self->redirect_to($return);
    }
    else {
        $self->render(status=>404,text=>'REJECTED');
    }
};

get 'fake_token' => sub {
    my $self=shift;
    if($self->param('client_id') && 
       $self->param('callback_url') && 
       $self->param('code')) {
           my $qp=Mojo::Parameters->new(access_token=>'fake_token',lifetime=>3600);
        $self->render(text=>'to_string');
    }
};

my $t=Test::Mojo->new;

$t->get_ok('/oauth')->status_is(302); # ->content_like(qr/bar/);
my $location=Mojo::URL->new($t->tx->res->headers->location);
my $callback_url=Mojo::URL->new($location->query->param('redirect_uri'));
is($location->query->param('client_id'),'fake_key');
$t->get_ok($location)->status_is(302);
my $res=Mojo::URL->new($t->tx->res->headers->location);
is($res->path,$callback_url->path,'Returns to the right place');
is($res->query->param('code'),'fake_code','Includes fake code');
done_testing;