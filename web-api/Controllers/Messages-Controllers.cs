using Microsoft.AspNetCore.Mvc;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

[Route("api/[controller]")]
[ApiController]
public class MessagesController : ControllerBase
{
    private const string dbFilePath = "messages.json";

    public class Message
    {
        public int Id { get; set; }
        public string Texto { get; set; }
        public DateTime DataHora { get; set; }
        public string Email { get; set; }
    }

    private List<Message> ReadMessagesFromJsonFile()
    {
        if (!System.IO.File.Exists(dbFilePath))
            return new List<Message>();

        string json = System.IO.File.ReadAllText(dbFilePath);
        var jsonObject = JsonConvert.DeserializeObject<JObject>(json);

        if (jsonObject.TryGetValue("msgs", out JToken msgsToken))
        {
            return msgsToken.ToObject<List<Message>>() ?? new List<Message>();
        }

        return new List<Message>();
    }

    private void SaveMessagesToJsonFile(List<Message> messages)
    {
        var jsonObject = new JObject();
        jsonObject["msgs"] = JArray.FromObject(messages);

        string json = jsonObject.ToString(Formatting.Indented);
        System.IO.File.WriteAllText(dbFilePath, json);
    }

    [HttpGet]
    public ActionResult<IEnumerable<Message>> Get()
    {
        var messages = ReadMessagesFromJsonFile();
        return Ok(messages);
    }

    [HttpPost]
    public ActionResult<Message> Post(Message message)
    {
        var messages = ReadMessagesFromJsonFile();

        message.Id = messages.Count > 0 ? messages.Max(m => m.Id) + 1 : 1;
        message.DataHora = DateTime.Now;
        messages.Add(message);

        SaveMessagesToJsonFile(messages);

        return CreatedAtAction(nameof(Get), new { id = message.Id }, message);
    }

    [HttpDelete("{id}")]
    public IActionResult Delete(int id)
    {
        var messages = ReadMessagesFromJsonFile();

        var message = messages.FirstOrDefault(m => m.Id == id);
        if (message == null)
        {
            return NotFound();
        }

        messages.Remove(message);

        SaveMessagesToJsonFile(messages);

        return NoContent();
    }
}
