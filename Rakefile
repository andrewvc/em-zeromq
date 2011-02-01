
begin
  require 'bones'
rescue LoadError
  abort '### Please install the "bones" gem ###'
end

#task :default => 'test:run'
task 'gem:release' => 'test:run'
  
#depend_on 'ffi-rzmq', '0.7.0'
#depend_on 'eventmachine'

Bones {
  name  'em-zeromq'
  authors  'Andrew Cholakian'
  email    'andrew@andrewvc.com'
  url      'https://github.com/andrewvc/em-zeromq'
}

