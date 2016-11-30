using System.Collections.Generic;
using System.Linq;
using System.Web.Mvc;
using Castle.Core.Internal;
using CommerceTraining.SupportingClasses;
using EPiServer;
using EPiServer.Commerce.Catalog.ContentTypes;
using EPiServer.Core;
using EPiServer.Framework.DataAnnotations;
using EPiServer.Web.Mvc;
using EPiServer.Web.Routing;
using EPiServer.Web.Routing;
using EPiServer.Commerce.Catalog;
using EPiServer.Filters;
using Mediachase.Commerce.Catalog.Objects;

namespace CommerceTraining.Controllers
{
    public class MyControllerBase<T> : ContentController<T> where T : CatalogContentBase
    {
        public readonly IContentLoader _contentLoader;
        public readonly UrlResolver _urlResolver;
        public readonly AssetUrlResolver _assetUrlResolver;
        public readonly ThumbnailUrlResolver _thumbnailUrlResolver;

        public MyControllerBase(IContentLoader contentLoader,
            UrlResolver urlResolver,
            AssetUrlResolver assetUrlResolver,
            ThumbnailUrlResolver thumbnailUrlResolver)
        {
            _contentLoader = contentLoader;
            _urlResolver = urlResolver;
            _assetUrlResolver = assetUrlResolver;
            _thumbnailUrlResolver = thumbnailUrlResolver;
        }

        public string GetDefaultAsset(IAssetContainer assetContainer)
        {
            return _assetUrlResolver.GetAssetUrl(assetContainer);
        }

        public string GetNamedAsset(IAssetContainer assetContainer, string name)
        {
            return _thumbnailUrlResolver.GetThumbnailUrl(assetContainer, name);
        }

        public string GetUrl(ContentReference contentReference)
        {
            return _urlResolver.GetUrl(contentReference);
        }

        public List<NameAndUrls> GetNodes(ContentReference contentReference)
        {
            var nodes = new List<NameAndUrls>();
            var nodeContent = FilterForVisitor.Filter(_contentLoader.GetChildren<NodeContent>(contentReference));
            if (!nodeContent.IsNullOrEmpty())
            {
                foreach (var node in nodeContent)
                {
                    var n = node as NodeContent;
                    nodes.Add(new NameAndUrls
                    {
                        name = node.Name,
                        url = GetUrl(node.ContentLink),
                        imageUrl = GetDefaultAsset(n),
                        imageTumbUrl = GetNamedAsset(n, "Thumbnail")
                    });
                }
            }
            return nodes;
        }

        public List<NameAndUrls> GetEntries(ContentReference contentReference)
        {
            var entries = new List<NameAndUrls>();
            var entryContent = FilterForVisitor.Filter(_contentLoader.GetChildren<EntryContentBase>(contentReference));
            if (!entryContent.IsNullOrEmpty())
            {
                foreach (var entry in entryContent)
                {
                    var e = entry as EntryContentBase;
                    entries.Add(new NameAndUrls
                    {
                        name = entry.Name,
                        url = GetUrl(entry.ContentLink),
                        imageUrl = GetDefaultAsset(e),
                        imageTumbUrl = GetNamedAsset(e,"Thumbnail")
                    });
                }
            }
            return entries;
        }
    }
}