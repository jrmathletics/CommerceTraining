using System.Collections.Generic;
using System.Linq;
using System.Web.Mvc;
using Castle.MicroKernel.Registration;
using CommerceTraining.Models.Catalog;
using CommerceTraining.SupportingClasses;
using EPiServer;
using EPiServer.Commerce.Catalog;
using EPiServer.Core;
using EPiServer.Framework.DataAnnotations;
using EPiServer.Web.Mvc;
using EPiServer.Web.Routing;

namespace CommerceTraining.Controllers
{
    public class NodeController : MyControllerBase<ShirtNode>
    {
        public ActionResult Index(ShirtNode currentContent)
        {

            NodeEntryCombo nodeEntryCombo = new NodeEntryCombo();
            nodeEntryCombo.nodes = GetNodes(currentContent.ContentLink);
            nodeEntryCombo.entries = GetEntries(currentContent.ContentLink);
            return View(nodeEntryCombo);
        }

        public NodeController(IContentLoader contentLoader, UrlResolver urlResolver, AssetUrlResolver assetUrlResolver, ThumbnailUrlResolver thumbnailUrlResolver) : base(contentLoader, urlResolver, assetUrlResolver, thumbnailUrlResolver)
        {
        }
    }
}