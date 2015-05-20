#encoding: utf-8
require 'csv'
require 'time'
require 'fileutils'
$csvFile = "/home/paul/coding/gemeindeliste/data/list.csv"
$imagesDir = "/home/paul/coding/gemeindeliste/pictures/"
$targets = ['full']
#$targets = ['justNames']
def col(a)
    a.ord - 65
end

$vorname = col 'D'
$nachname = col 'C'
$dienst = col 'N'
$taufe = col 'P'
$kinder = col 'R'
$geb = col 'M'
$tel = col 'E'
$mobil = col 'F'

$str = col 'I'
$plz = col 'J'
$stadt = col 'K'

$email = col 'H'
$sort = col 'S'

class Template
    def initialize(content)
        @file_content = content
    end
    def set(name,value)
         begin
            @file_content[":{" + name + "}:"] = value;
         rescue
            begin
                @file_content[":{" + name + "}:"] = "";
            rescue
            end
            #puts "No " + name;
         end
    end

    def generate()
        @file_content
    end
end

def tee(y,x)
    return "" if x == nil || x.strip == ""
    y + x
end
def validData?(d)
    d != nil && d.strip != "" && d != " "
end
def read_data(file)
    ret = []
    i = 0
    CSV.foreach(file) do |row|
        i += 1
        next if i == 1
        ret << row
    end
    return ret
end

def render_target(target_name)
    main_html = Template.new(File.read("templates/#{target_name}/main.html"));
    item_html = File.read("templates/#{target_name}/item.html");
    
    item_out = "";
    data = read_data($csvFile)
    data.sort!{|x,y| x[$sort] <=> y[$sort]}
    #data = sort_data(data)
    data.each do |row|
        item = Template.new(item_html.dup)
        item.set("vorname", row[$vorname]);
        item.set("nachname", row[$nachname]);
        item.set("dienst", tee("Dienst: ",row[$dienst]));
        
        item.set("kinder", tee("Kinder: ",row[$kinder]));
        
        geb = row[$geb]
        taufe = row[$taufe]
        if(validData? taufe)
            begin
                t2 = Date.parse(taufe)
                item.set("taufe", "T: " + t2.strftime("%d.%m.%Y"));
            rescue
                puts "invalid taufe #{taufe} von #{row[$vorname]} #{row[$nachname]}"
            end
           
        else 
            puts "Keine Taufe: #{row[$vorname]} #{row[$nachname]}"
            item.set("taufe", "");
        end
        if(validData? geb)
            begin
                t1 = Date.parse(geb)
                item.set("geb", "G: " + t1.strftime("%d.%m.%Y"));
            rescue
                puts "invalid date #{geb} in #{row[$vorname]}" 
            end
        else 
            puts "Keine Geburtstag: #{row[$vorname]} #{row[$nachname]}"
            item.set("geb", "");
        end
       
        item.set("tel", row[$tel]);
        item.set("str", row[$str]);
        item.set("stadt", row[$stadt]);
        item.set("plz", row[$plz]);
        item.set("mobil", row[$mobil]);
        item.set("email", tee("E-Mail: ",row[$email]));
        
        img_name = "#{$imagesDir}#{row[$nachname].capitalize}_#{row[$vorname].capitalize}.jpg"
        item.set("img", img_name)
        item_out += item.generate();
        
    end
    main_html.set("content", item_out);
    FileUtils.rmdir("output/");
    FileUtils.mkpath("output/");
    File.open("output/#{target_name}.html", 'w') { |file| file.write(main_html.generate()) }
    
    system("prince \"output/#{target_name}.html\" -s \"stylesheets/#{target_name}.css\" -o \"output/#{target_name}.pdf\"");
end

system("compass compile");
$targets.each do |target|
    render_target(target)
end
