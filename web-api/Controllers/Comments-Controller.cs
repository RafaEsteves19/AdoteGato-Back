using Microsoft.AspNetCore.Mvc;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

[Route("api/[controller]")]
[ApiController]
public class CommentsController : ControllerBase
{
    private const string DbFilePath = "db.json";

    public class Comment
    {
        public int Id { get; set; }
        public int EventId { get; set; }
        public string Del { get; set; }
        public DateTime DataHora { get; set; }
        public string Text { get; set; }
        public string Email { get; set; }
    }

    private List<Comment> ReadCommentsFromJsonFile()
    {
        if (!System.IO.File.Exists(DbFilePath))
        {
            return new List<Comment>();
        }

        string json = System.IO.File.ReadAllText(DbFilePath);
        var jsonObject = JsonConvert.DeserializeObject<JObject>(json);

        if (jsonObject.TryGetValue("cmnts", out JToken cmntsToken))
        {
            return cmntsToken.ToObject<List<Comment>>() ?? new List<Comment>();
        }

        return new List<Comment>();
    }

    private void SaveCommentsToJsonFile(List<Comment> comments)
    {
        var jsonObject = new JObject();
        jsonObject["cmnts"] = JArray.FromObject(comments);

        string json = jsonObject.ToString(Formatting.Indented);
        System.IO.File.WriteAllText(DbFilePath, json);
    }

    [HttpGet]
    public ActionResult<IEnumerable<Comment>> Get()
    {
        var comments = ReadCommentsFromJsonFile();
        return Ok(comments);
    }

    [HttpPost]
    public ActionResult<Comment> Post(Comment comment)
    {
        var comments = ReadCommentsFromJsonFile();

        comment.Id = comments.Count > 0 ? comments.Max(c => c.Id) + 1 : 1;
        comment.DataHora = DateTime.Now;
        var email = comment.Email;
        comments.Add(comment);

        SaveCommentsToJsonFile(comments);

        return CreatedAtAction(nameof(Get), new { id = comment.Id }, new { comment.Id, comment.EventId, comment.Del, comment.DataHora, comment.Text, Email = email });
    }

    [HttpDelete("{del}")]
    public IActionResult Delete(string del)
    {
        var comments = ReadCommentsFromJsonFile();

        if (!int.TryParse(del, out int commentId))
        {
            return BadRequest("Invalid comment ID format");
        }

        var comment = comments.FirstOrDefault(c => c.Id == commentId);
        if (comment == null)
        {
            return NotFound();
        }

        comments.Remove(comment);

        SaveCommentsToJsonFile(comments);

        return NoContent();
    }
}
