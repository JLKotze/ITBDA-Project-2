import java.io.IOException;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Mapper;

public class LocationMapper
        extends Mapper<Object, Text, Text, Text> {

    private Text keyword = new Text();
    private Text location = new Text();
    private int rowNumber = 0;

    public void map(Object key, Text value, Context context) throws IOException, InterruptedException {
        // Increases after a line is read
        rowNumber++;
        
        // Reads line
        String line = value.toString();

        // Retrieves the keyword
        String searchKeyword = context.getConfiguration().get("keyword");

        // Handles case-insensitivity
        String lowerLine = line.toLowerCase();
        String lowerKeyword = searchKeyword.toLowerCase();

        // Finds column value of keyword
        int column = lowerLine.indexOf(lowerKeyword);

    }
}