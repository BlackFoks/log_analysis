# coding: utf-8

# ===================
# Этот скрипт производит сравнения нового лога со старым и находит ошибки,
# отсутствующие в старом логе, но присутствующие в новом. Поиск ошибок осуществляется
# с помощью регекспов, способом идентификации ошибок выступает имя объекта, при 
# компиляции которого возникла ошибка, например HOUSE.REPAY_HOUSE или SYSTEM.IN_OPLAT.
#
# Известные проблемы:
#  * путь до файлов лога не должен включать кириллические символы
#  * Из-за отсутствия поддержки командной строкой кодировки utf-8, все выводимые 
#    данные кодируются в кодировке cp866 (IBM866), т.ч. при перенаправлении вывода 
#    в файл (> log.rb log1.txt log2.txt > output.txt) его кодировка будет cp866.
# ===================

# represents log file
class LogFile
  attr_reader :filename
  attr_reader :errors
  attr_reader :total_errors
  
  def initialize(filename)
    # prepare
    @filename = filename
    @errors = []
    @total_errors = []
    
    # open file
    @file = File.open(@filename, 'r')
    
    # read file
    @file.each do |line|
      # parse compile errors
      if /.*\d+\/\d+\s+: \d - \d* \( (?<err_name>.*) \).*/ =~ line
        @errors << err_name
      end
      
      # parse itogs of compilation
      if /\s+\d+:\s(?<t_err_name>.*)$/ =~ line
        @total_errors << t_err_name
      end
    end
  end  
end

# print info
if ARGV.empty?
  puts "Программа для сравнения логов компиляции.\n\n".encode("cp866", "utf-8")
  puts "Использование: log.rb [старый лог] [новый лог]\n\n".encode("cp866", "utf-8")
  puts "Автор: Брагин Георгий (mail@blackfoks.com), 2011".encode("cp866", "utf-8")
  exit
end

# load logs
old_log = LogFile.new(ARGV[0]);
new_log = LogFile.new(ARGV[1]);

# get list of new errors
new_errors = []
new_log.errors.each do |err|
  if !old_log.errors.include?(err)
    new_errors << err
  end
end

new_total_errors = []
new_log.total_errors.each do |t_err|
  if !old_log.total_errors.include?(t_err)
    new_total_errors << t_err
  end
end

# puts list
if !new_errors.empty?
  puts "Новых ошибок: #{new_errors.count}\n".encode("cp866", "utf-8")
  puts 'Новые ошибки:'.encode("cp866", "utf-8")
  new_errors.each {|err| puts "  #{new_errors.index(err)+1}: #{err}" }
end

if !new_total_errors.empty?
  puts "\nПодробный список ошибок:\n".encode("cp866", "utf-8")
  new_total_errors.each {|t_err| puts "  #{new_total_errors.index(t_err)+1}: #{t_err}".encode('cp866', 'cp1251') }
end