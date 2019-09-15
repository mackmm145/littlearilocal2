SC_FOLDER = 'L:/sc/'
ALTDBF_FOLDER = 'L:/altdbf/'

# OPEN_CHECK_REQUEST_FOLDER = 'L:/sc/xml/REQUESTS_IN_LAJK/'.freeze
OPEN_CHECK_REQUEST_FOLDER = '/mnt/xml/REQUESTS_IN_LAJK'.freeze
# OPEN_CHECK_FOLDER = 'L:/sc/xml/OPENCHECKS_LAJK/'.freeze
OPEN_CHECK_FOLDER = '/mnt/xml/OPENCHECKS_LAJK'.freeze

QMMDB_FILE = '/home/makoto/dbx/Ruby/sites/QM.MDB'

if ENV['computer_loation'] == 'lajk'
  TCP_SOCKET_ADDRESS = "127.0.0.1"
else
  TCP_SOCKET_ADDRESS = "10.99.10.98"
end

TCP_SOCKET_PORT = 6880