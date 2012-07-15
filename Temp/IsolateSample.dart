#import('dart:html');
#import('dart:isolate');

void main() {
  
  port.receive((ReturnMessage message, SendPort replyTo) {
    print("Got message1: ${message.name}");
    //port.close();  
  });

  SendMessage sending = new SendMessage.create("brandon");
  
  SendPort sender = spawnFunction(process);
  sender.send(sending, port.toSendPort());
  
}

process() {
  port.receive((SendMessage message, SendPort replyTo) {
      ReturnMessage returnMessage = new ReturnMessage.create("close2 ${message.name}");
      replyTo.send(returnMessage);
      //port.close();  
  });
}


class SendMessage {
  String name;
  
  SendMessage.create(this.name);
}

class ReturnMessage {
  String name;
  
  ReturnMessage.create(this.name);
}