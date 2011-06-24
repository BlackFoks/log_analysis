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

def wputs(str)
  puts str.encode("cp866", str.encoding)
end

# print info
if ARGV.empty?
  wputs "Программа для сравнения логов компиляции.\n\n"
  wputs "Использование: log.rb [опции] [старый лог] [новый лог]\n\n"
  wputs "Автор: Брагин Георгий (mail@blackfoks.com), 2011"
  exit
end

wputs "\nСравниваю файлы...\n\n"

# load logs
old_log = LogFile.new(ARGV[-2]);
new_log = LogFile.new(ARGV[-1]);

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

wputs "Старый файл: #{old_log.filename}"
wputs "Новый файл: #{new_log.filename}\n\n"
wputs "Ошибок компиляции в старом файле: #{old_log.errors.count}"
wputs "Ошибок комниляции в новом файле : #{new_log.errors.count}"

d_errors = old_log.errors.count - new_log.errors.count
if d_errors > 0
  wputs "Устранено ошибок компиляции     : #{d_errors}"
elsif d_errors < 0
  wputs "Появилось ошибок компиляции     : #{d_errors}"
else
  wputs "Количество ошибок компиляции не извенилось"
end
puts

wputs "Всего ошибок в старом файле: #{old_log.total_errors.count}"
wputs "Всего ошибок в новом файле : #{new_log.total_errors.count}"

dt_errors = old_log.total_errors.count - new_log.total_errors.count
if d_errors > 0
  wputs "Всего устранено ошибок     : #{d_errors}"
elsif d_errors < 0
  wputs "Всего появилось ошибок     : #{d_errors}"
else
  wputs "Количество ошибок не извенилось"
end
puts

# puts list
if !new_errors.empty?
  wputs "Появилось новых ошибок: #{new_errors.count}\n"
  wputs 'Новые ошибки компиляции:'
  new_errors.each {|err| wputs "  #{new_errors.index(err)+1}: #{err}" }
end

if !new_total_errors.empty?
  wputs "\nПодробный (общий) список ошибок:\n"
  new_total_errors.each {|t_err| wputs "  #{new_total_errors.index(t_err)+1}: #{t_err}".encode('cp866', 'cp1251') }
end