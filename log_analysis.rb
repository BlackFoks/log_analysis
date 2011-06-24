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
    
    # open file
    @file = File.open(@filename, 'r')
    
    # read file
    @file.each do |line|      
      # parse errors
      if /\s+\d+:\s(?<err_name>.*)$/ =~ line
        @errors << err_name
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
new_errors = new_log.errors - old_log.errors

# puts info
wputs "Старый лог: #{old_log.filename}"
wputs "Новый лог: #{new_log.filename}\n\n"

# puts list of new errors
wputs "Ошибок в старом файле : #{old_log.errors.count}"
wputs "Ошибок в новом файле  : #{new_log.errors.count}"
# number of new errors
d_errors = old_log.errors.count - new_log.errors.count
if d_errors > 0
  wputs "Всего устранено ошибок: #{d_errors}"
elsif d_errors < 0
  wputs "Всего появилось ошибок: #{d_errors.abs}"
else
  wputs "Количество ошибок не изменилось"
end
puts

# puts list of new total errors
if !new_errors.empty?
  wputs "Появилось новых ошибок: #{new_errors.count}\n"
  wputs "\nНовые ошибки:\n"
  new_errors.each {|err| wputs "  #{new_errors.index(err)+1}: #{err}".encode('cp866', 'cp1251') }
end