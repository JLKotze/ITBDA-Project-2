import java.io.IOException;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;

public class LocationRunner {
    public static void main(String[] args)
            throws IOException, InterruptedException,
            ClassNotFoundException {

        // Validate command-line arguments
        if (args.length != 3) {
            System.err.println(
                    "Usage: LocationRunner <input> <output> <keyword>");
            System.exit(1);
        }

        // Create Hadoop configuration
        Configuration conf = new Configuration();

        // Set the search keyword
        conf.set("keyword", args[2]);

        // Create MapReduce job
        Job job = Job.getInstance(conf, "KeywordLocation");

        // Set main class
        job.setJarByClass(LocationRunner.class);

        // Set Mapper and Reducer classes
        job.setMapperClass(LocationMapper.class);
        job.setReducerClass(LocationReducer.class);

        // Set Mapper output types
        job.setMapOutputKeyClass(Text.class);
        job.setMapOutputValueClass(Text.class);

        // Set final output types
        job.setOutputKeyClass(Text.class);
        job.setOutputValueClass(Text.class);

        // Set input and output paths
        FileInputFormat.addInputPath(job, new Path(args[0]));
        FileOutputFormat.setOutputPath(job, new Path(args[1]));

        // Execute MapReduce job
        System.exit(job.waitForCompletion(true) ? 0 : 1);
    }
}
