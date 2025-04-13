use std::process::Command;
use serde::Serialize;
use serde_json;
fn main() {
    // Execute 'cliphist list' and capture its output
    let output = Command::new("cliphist")
        .arg("list")
        .output()
        .expect("Failed to execute 'cliphist list'");

    // Convert the stdout (in bytes) to a string
    let stdout = String::from_utf8_lossy(&output.stdout);

    // Split the output by newlines
    let lines = stdout.split('\n');
    

    // Iterate through the lines and process
    let data: Vec<PipeData> = lines.take(100).map(|line| {
        let mut title = None;
        let mut binary: Option<Vec<u8>> = None;
        let mut result = None;

        // Simple check to see if it's an image
        // (can fail if you have the special chars copied in your clipboard)
        if line.contains("��") {
            if let Some((id, _)) = line.split_once("\t"){
                let decoded_output = Command::new("cliphist")
                    .arg("decode")
                    .arg(id)
                    .output()
                    .expect("Failed to execute 'cliphist decode'");

                // Data for struct
                title = Some(line.to_string());
                binary = Some(decoded_output.stdout);
                result = Some(line.to_string());
            } 
            
        } else {
            title = Some(line.to_string());
        }

        // Return a PipeData instance
        PipeData {
            title,
            result,
            binary,
            // icon_size: Some(100),
        }
    }).collect();

    // Serialize to json and print
    let json = serde_json::to_string(&data).expect("failed to serialize");
    print!("{}", json);
}



#[derive(Debug, Serialize, Clone)]
pub struct PipeData {
    pub title: Option<String>,
    pub result: Option<String>,
    pub binary: Option<Vec<u8>>,
    // pub icon_size: Option<i32>,
}

