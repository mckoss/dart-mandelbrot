#import('dart:html');
#import('dart:isolate');

void main() {
  
  port.receive((ResponseData message, SendPort replyTo) {
    print("Got message1: ${message.name}");
    //port.close();  
  });

  WorkRequest work = new WorkRequest.create("brandon");
  
  SendPort sender = spawnFunction(process);
  sender.send(work, port.toSendPort());
  
}

process() {
  port.receive((WorkRequest message, SendPort replyTo) {
      ResponseData returnMessage = new ResponseData.create("close2 ${message.name}");
      replyTo.send(returnMessage);
      //port.close();  
  });
}


class WorkRequest {
  List<double> rc;
  int cx;
  int cy;
  
  WorkRequest(this.rc, this.cx, this.cy);
}
